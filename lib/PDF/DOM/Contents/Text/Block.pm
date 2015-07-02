use v6;

use PDF::DOM::Contents::Text::Line;
use PDF::DOM::Contents::Text::Atom;

class PDF::DOM::Contents::Text::Block {
    has Numeric $.line-height;
    has Numeric $.font-height;
    has Numeric $!width;
    has Numeric $!height;
    has @.lines;
    has @.overflow is rw;
    has Numeric $.font-size;
    has Str $!align where 'left' | 'center' | 'right' | 'justify';
    has Str $.valign where 'top' | 'center' | 'bottom';

    method actual-width  { @!lines.max({ .actual-width }); }
    method actual-height { (+@!lines - 1) * $!line-height  +  $!font-height }

    multi submethod BUILD(Str :$text!,
                          :$font!, :$font-size=16, :$!font-height = $font.height( $font-size ),
                          :$word-spacing = $font.stringwidth( ' ', $font-size ),
                          :$kern = False,
                          *%etc) {
        # assume uniform simple text, for now
        my @chunks = $text.comb(/ [ <![ - ]> [ \w | <:Punctuation> ] ]+ '-'?
                                || .
                                /).map( -> $word {
                                    $kern
                                        ?? $font.kern($word, $font-size, :$kern).list
                                        !! $word
                                 });

        constant NO-BREAK-WS = rx/ <[ \c[NO-BREAK SPACE] \c[NARROW NO-BREAK SPACE] \c[WORD JOINER] ]> /;
        constant BREAKING-WS = rx/ <![ \c[NO-BREAK SPACE] \c[NARROW NO-BREAK SPACE] \c[WORD JOINER] ]> \s /;

        my @atoms;
        while @chunks {
            my $content = @chunks.shift;
            my %atom = :$content;
            %atom<space> = @chunks && @chunks[0] ~~ Numeric
                ?? @chunks.shift
                !! 0;
            %atom<width> = $font.stringwidth($content, $font-size, :$kern);
            # don't atomize regular white-space
            next if $content ~~ BREAKING-WS;
            my $followed-by-ws = @chunks && @chunks[0] ~~ BREAKING-WS;
            my $kerning = %atom<space> < 0;

            my $atom = PDF::DOM::Contents::Text::Atom.new( |%atom );
            if $kerning {
                $atom.sticky = True;
            }
            elsif $atom.content ~~ NO-BREAK-WS {
                $atom.elastic = True;
                $atom.sticky = True;
                @atoms[*-1].sticky = True
                    if @atoms;
            }
            elsif $followed-by-ws {
                $atom.elastic = True;
                $atom.space += $word-spacing;
            }

            my $encoded = [~] $font.encode( $atom.content );
            $atom.encoded = $encoded
                unless $encoded eq $atom.content;

            @atoms.push: $atom;
        }

        self.BUILD( :@atoms, :$font-size, |%etc );
    }

    multi submethod BUILD(:@atoms! is copy,
                          Numeric :$!font-size!,
                          Numeric :$!line-height = $!font-size * 1.1,
                          Numeric :$!width?,      #| optional constraint
                          Numeric :$!height?,     #| optional constraint
                          Str :$!align = 'left',
                          Str :$!valign = 'top',
        ) is default {

        my $line;
        my $line-width = 0.0;

        while @atoms {

            my @word;
            my $atom;

            repeat {
                $atom = @atoms.shift;
                @word.push: $atom;
            } while $atom.sticky && @atoms;

            my $word-width = [+] @word.map({ .width + .space });
            my $trailing-space = @word[*-1].space;

            if !$line || ($!width && $line.atoms && $line-width + $word-width - $trailing-space > $!width) {
                last if $!height && (@!lines + 1)  *  $!line-height > $!height;
                $line = PDF::DOM::Contents::Text::Line.new();
                $line-width = 0.0;
                @!lines.push: $line;
            }

            $line.atoms.push: @word;
            $line-width += $word-width;
        }

        for @!lines {
            .atoms[*-1].elastic = False;
            .atoms[*-1].space = 0;
            .align($!align);
        }

        @!overflow = @atoms;
    }

    method width  { $!width //= self.actual-width }
    method height { $!height //= self.actual-height }

    method align($!align) {
        .align($!align)
            for self.lines;
    }

    method content(Bool :$nl = False) {

        my @content = :TL[ $!line-height ];

        my $dy = do given $!valign {
            when 'center' { 0.5 }
            when 'bottom' { 1.0 }
            default { 0 }
        };

        @content.push: 'Td' => [0, $dy * $!height]
            if $dy && $!height;

        for $.lines.list {
            @content.push: .content(:$.font-size);
            @content.push: 'T*';
        }

        @content.pop
            if !$nl && @content;

        @content;
    }

}