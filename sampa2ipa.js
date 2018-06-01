#!/usr/bin/env nodejs
// For nodejs v0.10, as in Ubuntu 14.

// Convert X-SAMPA to IPA.
// Adapted from http://aveneca.com/xipa.html.
// Alternative converters:
// Paolo Mairano's http://phonetictools.altervista.org/phonverter/, view-source:http://phonetictools.altervista.org/phonverter/script.js
// Luis González Miranda's https://tools.lgm.cl/xsampa.html
// http://www.public.asu.edu/~athxo/convert_to_ipa.htm

// Called by phnrec.sh.

const readline = require('readline');
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

rl.on('line', function (tin) {
  tout = '';
  for (i = 0; i < tin.length; i++) {
    cc = tin.charAt(i);
    cn = tin.charAt(i + 1);
    ce = tin.charAt(i + 2);
    switch (cn) {
      case '`': {
        cd = cc.charCodeAt(0);
        switch (cc) {
          case '@': cd = 602; break;
          case 'd': cd = 598; break;
          case 'l': cd = 621; break;
          case 'n': cd = 627; break;
          case 'r': cd = 637; break;
          case 's': cd = 642; break;
          case 't': cd = 648; break;
          case 'z': cd = 656; break;
          default: i--;
        }
        cx = String.fromCharCode(cd);
        i++;
      }
      break;
      case '\\': {
        cd = 42;
        ii = 1;
        switch (cc) {
          case '!': cd = 451; break;
          case '-': cd = 8255; break;
          case '3': cd = 606; break;
          case ':': cd = 721; break;
          case '<': cd = 674; break;
          case '=': cd = 450; break;
          case '>': cd = 673; break;
          case '?': cd = 661; break;
          case '@': cd = 600; break;
          case 'B': cd = 665; break;
          case 'G': if (ce != '_') cd = 610; else { cd = 667; ii = 3; } break;
          case 'H': cd = 668; break;
          case 'J': if (ce != '_') cd = 607; else { cd = 644; ii = 3; } break;
          case 'K': cd = 622; break;
          case 'L': cd = 671; break;
          case 'M': cd = 624; break;
          case 'N': cd = 628; break;
          case 'O': cd = 664; break;
          case 'R': cd = 640; break;
          case 'X': cd = 295; break;
          case 'h': cd = 614; break;
          case 'j': cd = 669; break;
          case 'l': cd = 634; break;
          case 'p': cd = 632; break;
          case 'r': if (ce != '`') cd = 633; else { cd = 635; ii = 2; } break;
          case 's': cd = 597; break;
          case 'v': cd = 651; break;
          case 'x': cd = 615; break;
          case 'z': cd = 657; break;
          case '|': if (ce != '|') cd = 448; else { cd = 449; ii = 3; } break;
        }
        cx = String.fromCharCode(cd);
        i += ii;
      }
      break;
      case '_':
        if (ce == '<') {
          cd = 42;
          switch (cc) {
            case 'b': cd = 595; i += 2; break;
            case 'd': cd = 599; i += 2; break;
            case 'g': cd = 608; i += 2; break;
          }
          cx = String.fromCharCode(cd);
          break;
        }
      default: {
        cd = cc.charCodeAt(0);
        switch (cc) {
          case '!': cd = 8595; break;
          case '"': cd = 712; break;
          case '%': cd = 716; break;
          case '^': cd = 8593; break;
          case '&': cd = 630; break;
          case "'": cd = 690; break;
          case '1': cd = 616; break;
          case '2': cd = 248; break;
          case '3': cd = 604; break;
          case '4': cd = 638; break;
          case '5': cd = 619; break;
          case '6': cd = 592; break;
          case '7': cd = 612; break;
          case '8': cd = 629; break;
          case '9': cd = 339; break;
          case ':': cd = 720; break;
          case '<': if (ce == '>') {
            switch (cn) {
              case 'F': cd = 8600; break;
              case 'R': cd = 8599; break;
            }
            i += 2;
          }
          break;
          case '=': cd = 809; break;
          case '?': cd = 660; break;
          case '@': cd = 601; break;
          case 'A': cd = 593; break;
          case 'B': cd = 946; break;
          case 'C': cd = 231; break;
          case 'D': cd = 240; break;
          case 'E': cd = 603; break;
          case 'F': cd = 625; break;
          case 'G': cd = 611; break;
          case 'H': cd = 613; break;
          case 'I': cd = 618; break;
          case 'J': cd = 626; break;
          case 'K': cd = 620; break;
          case 'L': cd = 654; break;
          case 'M': cd = 623; break;
          case 'N': cd = 331; break;
          case 'O': cd = 596; break;
          case 'Q': cd = 594; break;
          case 'P': cd = 651; break;
          case 'R': cd = 641; break;
          case 'S': cd = 643; break;
          case 'T': cd = 952; break;
          case 'U': cd = 650; break;
          case 'V': cd = 652; break;
          case 'W': cd = 653; break;
          case 'X': cd = 967; break;
          case 'Y': cd = 655; break;
          case 'Z': cd = 658; break;
          case '{': cd = 230; break;
          case '}': cd = 649; break;
          case '_': {
            ii = 1;
            switch (cn) {
              case '"': cd = 776; break;
              case '+': cd = 799; break;
              case '-': cd = 800; break;
              case '0': cd = 805; break;
              case '=': cd = 809; break;
              case '>': cd = 700; break;
              case '?': if (ce == '\\') { cd = 740; i++; } break;
              case 'O': cd = 825; break;
              case 'A': cd = 792; break;
              case 'B': cd = 783; break;
              case 'F': cd = 770; break;
              case 'G': cd = 736; break;
              case 'H': cd = 769; break;
              case 'L': cd = 768; break;
              case 'M': cd = 772; break;
              case 'N': cd = 828; break;
              case 'R': cd = 780; break;
              case 'T': cd = 779; break;
              case 'X': cd = 774; break;
              case 'c': cd = 796; break;
              case '^': cd = 815; break;
              case 'a': cd = 826; break;
              case 'd': cd = 810; break;
              case 'e': cd = 820; break;
              case 'h': cd = 688; break;
              case 'k': cd = 816; break;
              case 'l': cd = 737; break;
              case 'm': cd = 827; break;
              case 'n': cd = 8319; break;
              case 'o': cd = 798; break;
              case 'q': cd = 793; break;
              case 'r': cd = 797; break;
              case 't': cd = 804; break;
              case 'v': cd = 812; break;
              case 'w': cd = 695; break;
              case 'x': cd = 829; break;
              case '}': cd = 794; break;
              case '~': cd = 771; break;
            }
            i += ii;
          }
          break;
          case '`': cd = 734; break;
          case '~': cd = 771; break;
        }
        cx = String.fromCharCode(cd);
      }
    }
    tout += cx;
  }
  console.log(tout);
});
