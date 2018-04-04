/*

	             Encode MIDI file into simple MIDI format

	Re-worked from MIDICSV, by John Walker.
  midi-json is by Pube Douchevitz.
  www.spermwhale.info


*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#endif

#include "version.h"
#include "types.h"
#include "midifile.h"
#include "midio.h"
#include "getopt.h"
#include "midi-json.h"

#define FALSE	0
#define TRUE	1

static char *progname;		      /* Program name string */
static int verbose = FALSE; 	      /* Debug output */

/*  VLENGTH  --  Parse variable length item from in-memory track  */

static vlint vlength(byte **trk, long *trklen)
{
    vlint value;
    byte ch;
    byte *cp = *trk;

    trklen--;
    if ((value = *cp++) & 0x80) {
	value &= 0x7F;
	do {
	    value = (value << 7) | ((ch = *cp++) & 0x7F);
	    trklen--;
	} while (ch & 0x80);
    }
#ifdef DUMP
    fprintf(stderr, "Time lapse: %d bytes, %d\n", cp - *trk, value);
#endif
    *trk = cp;
    return value;
}

// parsing text in the MIDI file...

#define Quote_ISO

static void textToJson(FILE *fo, const byte *t, const int len)
{
    byte c;
    int i;

    putc('"', fo);
    for (i = 0; i < len; i++) {
    	c = *t++;
        if ((c < ' ') ||
#ifdef Quote_ISO
	    ((c > '~') && (c <= 160))
#else
    	    (c > '~')
#endif
	   ) {
            putc('\\', fo);
            putc('u', fo);
            fprintf(fo, "%04o", c);
	} else {
            if (c == '"') {
                putc('"', fo);
            } else if (c == '\\') {
                putc('\\', fo);
	    }
	    putc(c, fo);
	}
    }
    putc('"', fo);
}

//processing the track data...

static void trackToJson(FILE *fo, const int trackno,
    	    	     byte *trk, long trklen, const int ppq)
{
    int levt = 0, evt, channel, note, vel, value,
	type;
    vlint len;
    byte *titem;
    vlint abstime = 0;		      /* Absolute time in track */

    while (trklen > 0) {
	vlint tlapse = vlength(&trk, &trklen);
	abstime += tlapse;

        fprintf(fo, "{ \"track_no\": %d, \"abs_time\": %ld, ", trackno, abstime);

	/* Handle running status; if the next byte is a data byte,
	   reuse the last command seen in the track. */

	if (*trk & 0x80) {
	    evt = *trk++;
	    
	    /* One subtlety: we only save channel voice messages
	       for running status.  System messages and file
	       meta-events (all of which are in the 0xF0-0xFF
	       range) are not saved, as it is possible to carry a
	       running status across them.  You may have never seen
	       this done in a MIDI file, but I have. */
	       
	    if ((evt & 0xF0) != 0xF0) {
	    	levt = evt;
	    }
	    trklen--;
	} else {
	    evt = levt;
	}

	channel = evt & 0xF;

	/* Channel messages */

	switch (evt & 0xF0) {

	    case NoteOff:	 /* Note off */
		if (trklen < 2) { // i guess one of those returns.
		   fprintf(fo, "\"type\": \"NULL\"},\n"); 
       return;
		}
		trklen -= 2;
		note = *trk++;
		vel = *trk++;
                fprintf(fo, "\"type\": \"Note_off_c\", \"channel\": %d, \"note\": %d, \"vel\": %d },\n", channel, note, vel);
		continue;

	    case NoteOn:	 /* Note on */
		if (trklen < 2) {
		   fprintf(fo, "\"no_track\": 1},\n"); 
		    return;
		}
		trklen -= 2;
		note = *trk++;
		vel = *trk++;
		/*  A note on with a velocity of 0 is actually a note
		    off.  We do not translate it to a Note_off record
		    in order to preserve the original structure of the
		    MIDI file.	*/
                fprintf(fo, "\"type\": \"Note_on_c\", \"channel\": %d, \"note\": %d, \"vel\": %d },\n", channel, note, vel);
		continue;

	    case PolyphonicKeyPressure: /* Aftertouch */
		if (trklen < 2) {
		   fprintf(fo, "\"no_track\": 1},\n"); 
		    return;
		}
		trklen -= 2;
		note = *trk++;
		vel = *trk++;
                fprintf(fo, "\"type\": \"Poly_aftertouch_c\", \"channel\": %d, \"note\": %d, \"vel\": %d },\n", channel, note, vel);
		continue;

	    case ControlChange:  /* Control change */
		if (trklen < 2) {
		   fprintf(fo, "\"no_track\": 1},\n"); 
		    return;
		}
		trklen -= 2;
		value = *trk++;
                fprintf(fo, "\"type\": \"Control_c\", \"channel\": %d, \"note\": %d, \"vel\": %d },\n", channel, note, vel);
		continue;

	    case ProgramChange:  /* Program change */
		if (trklen < 1) {
		  return;
		}
		trklen--;
		note = *trk++;
                fprintf(fo, "\"type\": \"Program_c\", \"channel\": %d, \"note\": %d},\n", channel, note);
		continue;

	    case ChannelPressure: /* Channel pressure (aftertouch) */
		if (trklen < 1) {
		   fprintf(fo, "\"no_track\": 1},\n"); 
		    return;
		}
		trklen--;
		vel = *trk++;
                fprintf(fo, "\"type\": \"Channel_aftertouch_c\", \"channel\": %d, \"vel\": %d},\n", channel, vel);
		continue;

	    case PitchBend:	 /* Pitch bend */
	       if (trklen < 1) {
		   fprintf(fo, "\"no_track\": 1},\n"); 
		   return;
		}
		trklen--;
		value = *trk++;
		value = value | ((*trk++) << 7);
                fprintf(fo, "\"type\": \"Pitch_bend_c\", \"channel\": %d, \"value\": %d},\n", channel, value);
		continue;

	    default:

		break;
	}

	switch (evt) {

	    /* System exclusive messages */

	    case SystemExclusive:
	    case SystemExclusivePacket:
		len = vlength(&trk, &trklen);
//what about this? same, just in json format somehting like this.
                fprintf(fo, "\"type\": \"System_exclusive%s\", \"length\": %lu",
                    evt == SystemExclusivePacket ? "_packet" : "",
		    len);
		{
		    vlint i;

        fprintf(fo, "\"track_%d\": %d", 0, *trk++);
		    for (i = 1; i < len; i++) {
                        fprintf(fo, ", \"track_%d\": %d", (int)i, (int)*trk++);
		    }
                    fprintf(fo, "},\n");
		}
		break;

	    /* File meta-events */

	    case FileMetaEvent:

		if (trklen < 2) {
		   fprintf(fo, "\"no_track\": 1},\n"); 
		    return;
		}
		trklen -= 2;
		type = *trk++;
		len = vlength(&trk, &trklen);
		titem = trk;
		trk += len;
		trklen -= len;

		switch (type) {
		    case SequenceNumberMetaEvent:

                        fprintf(fo, "\"type\": \"Sequence_number\": \"value\": %d },\n", (titem[0] << 8) | titem[1]);
			break;

		    case TextMetaEvent:
#ifdef XDD
fprintf(fo, " (Len=%ld  Trk=%02x) ", len, *trk);
#endif
    	    	    	fputs("\"type\": \"Text_t\", \"value\": ", fo);
			textToJson(fo, titem, len);
			fprintf(fo, "},\n");
			break;

		    case CopyrightMetaEvent:
    	    	    	fputs("\"type\": \"Copyright_t\", \"value\": ", fo);
			textToJson(fo, titem, len);
			fprintf(fo, "},\n");
			break;

		    case TrackTitleMetaEvent:
    	    	    	fputs("\"type\": \"Title_t\", \"value\": ", fo);
			textToJson(fo, titem, len);
			fprintf(fo, "},\n");
			break;

		    case TrackInstrumentNameMetaEvent:
    	    	    	fputs("\"type\": \"Instrument_name_t\", \"value\": ", fo);
			textToJson(fo, titem, len);
			fprintf(fo, "},\n");
			break;

		    case LyricMetaEvent:
    	    	    	fputs("\"type\": \"Lyric_t\", \"value\": ", fo);
			textToJson(fo, titem, len);
			fprintf(fo, "},\n");
			break;

		    case MarkerMetaEvent:
    	    	    	fputs("\"type\": \"Marker_t\": \"value\": ", fo);
			textToJson(fo, titem, len);
			fprintf(fo, "},\n");
			break;

		    case CuePointMetaEvent:
    	    	    	fputs("\"type\": \"Cue_point_t\", \"value\": ", fo);
			textToJson(fo, titem, len);
			fprintf(fo, "},\n");
			break;
		    case ChannelPrefixMetaEvent:
                        fprintf(fo, "\"type\": \"Channel_prefix\", \"value\": %d },\n", titem[0]);
			break;

		    case PortMetaEvent:
                        fprintf(fo, "\"type\": \"MIDI_port\", \"value\": %d },\n", titem[0]);
			break;

		    case EndTrackMetaEvent:
                        fprintf(fo, "\"type\": \"End_track\"},\n");
			trklen = -1;
			break;

		    case SetTempoMetaEvent:
                        fprintf(fo, "\"type\": \"Tempo\", \"number\": %d},\n", (titem[0] << 16) |
			       (titem[1] << 8) | titem[2]);
			break;

		    case SMPTEOffsetMetaEvent:
                        fprintf(fo, "\"type\": \"SMPTE_offset\", \"hour\": %d, \"minute\": %d, \"second\": %d, \"frame\": %d, \"frac_frame\": %d },\n",
			    titem[0], titem[1], titem[2], titem[3], titem[4]);
			break;

		    case TimeSignatureMetaEvent:
                        fprintf(fo, "\"type\": \"Time_signature\", \"numerator\": %d, \"denominator\": %d, \"click\": %d, \"notesQ\": %d },\n",
				titem[0], titem[1], titem[2], titem[3]);
			break;

		    case KeySignatureMetaEvent:
                        fprintf(fo, "\"type\": \"Key_signature\", \"key\": %d, \"major_minor\": \"%s\"},\n", ((signed char) titem[0]),
                                titem[1] ? "minor" : "major");
			break;

		    case SequencerSpecificMetaEvent:
                        fprintf(fo, "\"type\": \"Sequencer_specific\", \"length\": %lu, \"data\": [", len);
			{
			    vlint i;

          fprintf(fo, " %d", titem[0]);
			    for (i = 1; i < len; i++) {
                                fprintf(fo, ", %d", titem[i]);
			    }
                            fprintf(fo, "]");
                            fprintf(fo, "},\n");
			}
			break;

		    default:
			if (verbose) {
                            fprintf(stderr, "Unknown meta event type 0x%02X, %ld bytes of data.\n",
				    type, len);
			}
                        fprintf(fo, "\"type\": \"Unknown_meta_event\", \"event_type\": %d, \"length\": %lu, \"data\": [", type, len);
			{
			    vlint i;
          fprintf(fo, " %d", titem[0]);

			    for (i = 1; i < len; i++) {
                                fprintf(fo, ", %d", titem[i]);
			    }
                            fprintf(fo, "]");
                            fprintf(fo, "},\n");
			}
			break;
	      }
	      break;

	   default:
	      if (verbose) {
                  fprintf(stderr, "Unknown event type 0x%02X.\n", evt);
	      }
              fprintf(fo, "{ \"type\": \"Unknown_event\", \"value\": %02Xx},\n", evt);
	      break;
	}
    }
}


/*  Main program.  */

int midiJSONMainWrapper(int argc, char *argv[], const char *inPath, const char *outPath)
{
    struct mhead mh;
    FILE *fp, *fo;
    int i, n; 
    progname = argv[0];

    fp = fopen(inPath, "rb");
    if (fp == NULL) {
        fprintf(stderr, "%s: Unable to to open MIDI input file %s\n",
                progname, inPath);
        return 2;
    }
    fo = fopen(outPath, "w");
    if (fo == NULL) {
        fprintf(stderr, "%s: Unable to to create JSON output file %s\n",
                progname, outPath);
        return 2;
    }
        while ((n = getopt(argc, argv, "uv")) != -1) {
	switch (n) {
            case 'u':
                fprintf(stderr, "Usage: %s [ options ] [ midi_file ] [ json_file ]\n", progname);
                fprintf(stderr, "       Options:\n");
                fprintf(stderr, "           -u            Print this message\n");
                fprintf(stderr, "           -v            Verbose: dump header and track information\n");
		fprintf(stderr, "Version %s\n", VERSION);
		return 0;

            case 'v':
		verbose = TRUE;
		break;

            case '?':
                fprintf(stderr, "%s: undefined option -%c specified.\n",
		    progname, n);
		return 2;
	}
    }

    i = 0;
    while (optind < argc) {
	switch (i++) {
	    case 0:
                if (strcmp(argv[optind], "-") != 0) {
                    fp = fopen(argv[optind], "rb");
		    if (fp == NULL) {
                        fprintf(stderr, "%s: Unable to to open MIDI input file %s\n",
				progname, argv[optind]);
			return 2;
		    }
		}
		break;

	    case 1:
                if (strcmp(argv[optind], "-") != 0) {
                    fo = fopen(argv[optind], "w");
		    if (fo == NULL) {
                        fprintf(stderr, "%s: Unable to to create JSON output file %s\n",
				progname, argv[optind]);
			return 2;
		    }
		}
		break;
	}
	optind++;
    }
#ifdef _WIN32

    /*  If input is from standard input, set the input file
    	mode to binary.  */

    if (fp == stdin) {
	_setmode(_fileno(fp), _O_BINARY);
    }
#endif

    /* Read and validate header */

    readMidiFileHeader(fp, &mh);
    if (memcmp(mh.chunktype, "MThd", sizeof mh.chunktype) != 0) {
        fprintf(stderr, "%s is not a Standard MIDI File.\n", argv[1]);
	return 2;
    }
    if (verbose) {
        fprintf(stderr, "Format %d MIDI file.  %d tracks, %d ticks per quarter note.\n",
	      mh.format, mh.ntrks, mh.division);
    }

    /*	Output header  */

    fprintf(fo, "[ { \"type\": \"Header\", \"track_no\": 0, \"abs_time\": 0, \"format\": %d, \"nTracks\": %d, \"division\": %d},\n", mh.format, mh.ntrks, mh.division);

    /*	Process tracks */

    for (i = 0; i < mh.ntrks; i++) {
	struct mtrack mt;
	byte *trk;

	readMidiTrackHeader(fp, &mt);
        if (memcmp(mt.chunktype, "MTrk", sizeof mt.chunktype) != 0) {
            fprintf(stderr, "Track %d header is invalid.\n", i + 1);
	    return 2;
	}

	if (verbose) {
            fprintf(stderr, "Track %d: length %ld.\n", i + 1, mt.length);
	}
        fprintf(fo, "{ \"track_no\": %d, \"abs_time\": 0, \"type\": \"Start_track\"},\n", i + 1);

	trk = (byte *) malloc(mt.length);
	if (trk == NULL) {
             fprintf(stderr, "%s: Cannot allocate %ld bytes for track.\n",
		progname, mt.length);
	     return 2;
	}

	fread((char *) trk, (int) mt.length, 1, fp);

	trackToJson(fo, i + 1, trk, mt.length, mh.division);
	free(trk);
    }
    fprintf(fo, "{ \"type\": \"End_of_file\", \"channel\": 0, \"track_no\": 0 } ]\n");
    fclose(fo);
    return 0;
}



