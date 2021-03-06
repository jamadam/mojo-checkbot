package Marquee::Types;
use strict;
use warnings;
use Mojo::Base -base;

has types => sub {{
    "3gp"     => ["video/3gpp"],
    "a"       => ["application/octet-stream"],
    "ai"      => ["application/postscript"],
    "aif"     => ["audio/x-aiff"],
    "aiff"    => ["audio/x-aiff"],
    "asc"     => ["application/pgp-signature"],
    "asf"     => ["video/x-ms-asf"],
    "asm"     => ["text/x-asm"],
    "asx"     => ["video/x-ms-asf"],
    "atom"    => ["application/atom+xml"],
    "au"      => ["audio/basic"],
    "avi"     => ["video/x-msvideo"],
    "bat"     => ["application/x-msdownload"],
    "bin"     => ["application/octet-stream"],
    "bmp"     => ["image/bmp"],
    "bz2"     => ["application/x-bzip2"],
    "c"       => ["text/x-c"],
    "cab"     => ["application/vnd.ms-cab-compressed"],
    "cc"      => ["text/x-c"],
    "chm"     => ["application/vnd.ms-htmlhelp"],
    "class"   => ["application/octet-stream"],
    "com"     => ["application/x-msdownload"],
    "conf"    => ["text/plain"],
    "cpp"     => ["text/x-c"],
    "crt"     => ["application/x-x509-ca-cert"],
    "css"     => ["text/css"],
    "csv"     => ["text/csv"],
    "cxx"     => ["text/x-c"],
    "deb"     => ["application/x-debian-package"],
    "der"     => ["application/x-x509-ca-cert"],
    "diff"    => ["text/x-diff"],
    "djv"     => ["image/vnd.djvu"],
    "djvu"    => ["image/vnd.djvu"],
    "dll"     => ["application/x-msdownload"],
    "dmg"     => ["application/octet-stream"],
    "doc"     => ["application/msword"],
    "dot"     => ["application/msword"],
    "dtd"     => ["application/xml-dtd"],
    "dvi"     => ["application/x-dvi"],
    "ear"     => ["application/java-archive"],
    "eml"     => ["message/rfc822"],
    "eps"     => ["application/postscript"],
    "exe"     => ["application/x-msdownload"],
    "f"       => ["text/x-fortran"],
    "f77"     => ["text/x-fortran"],
    "f90"     => ["text/x-fortran"],
    "flv"     => ["video/x-flv"],
    "for"     => ["text/x-fortran"],
    "gem"     => ["application/octet-stream"],
    "gemspec" => ["text/x-script.ruby"],
    "gif"     => ["image/gif"],
    "gz"      => ["application/x-gzip"],
    "h"       => ["text/x-c"],
    "hh"      => ["text/x-c"],
    "htm"     => ["text/html"],
    "html"    => ["text/html;charset=UTF-8"],
    "ico"     => ["image/vnd.microsoft.icon"],
    "ics"     => ["text/calendar"],
    "ifb"     => ["text/calendar"],
    "iso"     => ["application/octet-stream"],
    "jar"     => ["application/java-archive"],
    "java"    => ["text/x-java-source"],
    "jnlp"    => ["application/x-java-jnlp-file"],
    "jpeg"    => ["image/jpeg"],
    "jpg"     => ["image/jpeg"],
    "js"      => ["application/javascript"],
    "json"    => ["application/json"],
    "log"     => ["text/plain"],
    "m3u"     => ["audio/x-mpegurl"],
    "m4v"     => ["video/mp4"],
    "man"     => ["text/troff"],
    "manifest"=> ["text/cache-manifest"],
    "mathml"  => ["application/mathml+xml"],
    "mbox"    => ["application/mbox"],
    "mdoc"    => ["text/troff"],
    "me"      => ["text/troff"],
    "mid"     => ["audio/midi"],
    "midi"    => ["audio/midi"],
    "mime"    => ["message/rfc822"],
    "mml"     => ["application/mathml+xml"],
    "mng"     => ["video/x-mng"],
    "mov"     => ["video/quicktime"],
    "mp3"     => ["audio/mpeg"],
    "mp4"     => ["video/mp4"],
    "mp4v"    => ["video/mp4"],
    "mpeg"    => ["video/mpeg"],
    "mpg"     => ["video/mpeg"],
    "ms"      => ["text/troff"],
    "msi"     => ["application/x-msdownload"],
    "odp"     => ["application/vnd.oasis.opendocument.presentation"],
    "ods"     => ["application/vnd.oasis.opendocument.spreadsheet"],
    "odt"     => ["application/vnd.oasis.opendocument.text"],
    "ogg"     => ["application/ogg"],
    "ogv"     => ["video/ogg"],
    "p"       => ["text/x-pascal"],
    "pas"     => ["text/x-pascal"],
    "pbm"     => ["image/x-portable-bitmap"],
    "pdf"     => ["application/pdf"],
    "pem"     => ["application/x-x509-ca-cert"],
    "pgm"     => ["image/x-portable-graymap"],
    "pgp"     => ["application/pgp-encrypted"],
    "pkg"     => ["application/octet-stream"],
    "pl"      => ["text/x-script.perl"],
    "pm"      => ["text/x-script.perl-module"],
    "png"     => ["image/png"],
    "pnm"     => ["image/x-portable-anymap"],
    "ppm"     => ["image/x-portable-pixmap"],
    "pps"     => ["application/vnd.ms-powerpoint"],
    "ppt"     => ["application/vnd.ms-powerpoint"],
    "ps"      => ["application/postscript"],
    "psd"     => ["image/vnd.adobe.photoshop"],
    "py"      => ["text/x-script.python"],
    "qt"      => ["video/quicktime"],
    "ra"      => ["audio/x-pn-realaudio"],
    "rake"    => ["text/x-script.ruby"],
    "ram"     => ["audio/x-pn-realaudio"],
    "rar"     => ["application/x-rar-compressed"],
    "rb"      => ["text/x-script.ruby"],
    "rdf"     => ["application/rdf+xml"],
    "roff"    => ["text/troff"],
    "rpm"     => ["application/x-redhat-package-manager"],
    "rss"     => ["application/rss+xml"],
    "rtf"     => ["application/rtf"],
    "ru"      => ["text/x-script.ruby"],
    "s"       => ["text/x-asm"],
    "sgm"     => ["text/sgml"],
    "sgml"    => ["text/sgml"],
    "sh"      => ["application/x-sh"],
    "sig"     => ["application/pgp-signature"],
    "snd"     => ["audio/basic"],
    "so"      => ["application/octet-stream"],
    "svg"     => ["image/svg+xml"],
    "svgz"    => ["image/svg+xml"],
    "swf"     => ["application/x-shockwave-flash"],
    "t"       => ["text/troff"],
    "tar"     => ["application/x-tar"],
    "tbz"     => ["application/x-bzip-compressed-tar"],
    "tcl"     => ["application/x-tcl"],
    "tex"     => ["application/x-tex"],
    "texi"    => ["application/x-texinfo"],
    "texinfo" => ["application/x-texinfo"],
    "text"    => ["text/plain"],
    "tif"     => ["image/tiff"],
    "tiff"    => ["image/tiff"],
    "torrent" => ["application/x-bittorrent"],
    "tr"      => ["text/troff"],
    "txt"     => ["text/plain"],
    "vcf"     => ["text/x-vcard"],
    "vcs"     => ["text/x-vcalendar"],
    "vrml"    => ["model/vrml"],
    "war"     => ["application/java-archive"],
    "wav"     => ["audio/x-wav"],
    "wma"     => ["audio/x-ms-wma"],
    "wmv"     => ["video/x-ms-wmv"],
    "wmx"     => ["video/x-ms-wmx"],
    "wrl"     => ["model/vrml"],
    "wsdl"    => ["application/wsdl+xml"],
    "xbm"     => ["image/x-xbitmap"],
    "xhtml"   => ["application/xhtml+xml"],
    "xls"     => ["application/vnd.ms-excel"],
    "xml"     => ["application/xml"],
    "xpm"     => ["image/x-xpixmap"],
    "xsl"     => ["application/xml"],
    "xslt"    => ["application/xslt+xml"],
    "yaml"    => ["text/yaml"],
    "yml"     => ["text/yaml"],
    "zip"     => ["application/zip"],
}};

sub detect {
    my ($self, $accept, $prioritize) = @_;
  
    # Extract and prioritize MIME types
    my %types;
    /^\s*([^,; ]+)(?:\s*\;\s*q\s*=\s*(\d+(?:\.\d+)?))?\s*$/i
        and $types{lc $1} = defined $2 ? $2 : 1
        for split ',', defined $accept ? $accept : '';
    my @detected = sort { $types{$b} <=> $types{$a} } sort keys %types;
    return [] if !$prioritize && @detected > 1;
  
    # Detect extensions from MIME types
    my %reverse;
    my $types = $self->types;
    for my $ext (sort keys %$types) {
        my @types = @{$types->{$ext}};
        push @{$reverse{$_}}, $ext for map { s/\;.*$//; lc $_ } @types;
    }
    return [map { @{defined $reverse{$_} ? $reverse{$_} : []} } @detected];
}

sub type {
    my ($self, $ext, $type) = @_;
    return $self->types->{lc $ext}[0] unless $type;
    $self->types->{lc $ext} = ref $type ? $type : [$type];
    return $self;
}

sub type_by_path {
    my ($self, $path) = @_;
    while ($path =~ s{\.(\w+)$}{}) {
        if (my $type = $self->type($1)) {
            return $type;
        }
    }
}

1;

=head1 NAME

Mojolicious::Types - MIME types

=head1 SYNOPSIS

  use Mojolicious::Types;

  my $types = Mojolicious::Types->new;
  $types->type(foo => 'text/foo');
  say $types->type('foo');

=head1 DESCRIPTION

L<Mojolicious::Types> manages MIME types for L<Mojolicious>.

    "3gp"     => "video/3gpp",
    "a"       => "application/octet-stream",
    "ai"      => "application/postscript",
    "aif"     => "audio/x-aiff",
    "aiff"    => "audio/x-aiff",
    "asc"     => "application/pgp-signature",
    "asf"     => "video/x-ms-asf",
    "asm"     => "text/x-asm",
    "asx"     => "video/x-ms-asf",
    "atom"    => "application/atom+xml",
    "au"      => "audio/basic",
    "avi"     => "video/x-msvideo",
    "bat"     => "application/x-msdownload",
    "bin"     => "application/octet-stream",
    "bmp"     => "image/bmp",
    "bz2"     => "application/x-bzip2",
    "c"       => "text/x-c",
    "cab"     => "application/vnd.ms-cab-compressed",
    "cc"      => "text/x-c",
    "chm"     => "application/vnd.ms-htmlhelp",
    "class"   => "application/octet-stream",
    "com"     => "application/x-msdownload",
    "conf"    => "text/plain",
    "cpp"     => "text/x-c",
    "crt"     => "application/x-x509-ca-cert",
    "css"     => "text/css",
    "csv"     => "text/csv",
    "cxx"     => "text/x-c",
    "deb"     => "application/x-debian-package",
    "der"     => "application/x-x509-ca-cert",
    "diff"    => "text/x-diff",
    "djv"     => "image/vnd.djvu",
    "djvu"    => "image/vnd.djvu",
    "dll"     => "application/x-msdownload",
    "dmg"     => "application/octet-stream",
    "doc"     => "application/msword",
    "dot"     => "application/msword",
    "dtd"     => "application/xml-dtd",
    "dvi"     => "application/x-dvi",
    "ear"     => "application/java-archive",
    "eml"     => "message/rfc822",
    "eps"     => "application/postscript",
    "exe"     => "application/x-msdownload",
    "f"       => "text/x-fortran",
    "f77"     => "text/x-fortran",
    "f90"     => "text/x-fortran",
    "flv"     => "video/x-flv",
    "for"     => "text/x-fortran",
    "gem"     => "application/octet-stream",
    "gemspec" => "text/x-script.ruby",
    "gif"     => "image/gif",
    "gz"      => "application/x-gzip",
    "h"       => "text/x-c",
    "hh"      => "text/x-c",
    "htm"     => "text/html",
    "html"    => "text/html",
    "ico"     => "image/vnd.microsoft.icon",
    "ics"     => "text/calendar",
    "ifb"     => "text/calendar",
    "iso"     => "application/octet-stream",
    "jar"     => "application/java-archive",
    "java"    => "text/x-java-source",
    "jnlp"    => "application/x-java-jnlp-file",
    "jpeg"    => "image/jpeg",
    "jpg"     => "image/jpeg",
    "js"      => "application/javascript",
    "json"    => "application/json",
    "log"     => "text/plain",
    "m3u"     => "audio/x-mpegurl",
    "m4v"     => "video/mp4",
    "man"     => "text/troff",
    "manifest"=> "text/cache-manifest",
    "mathml"  => "application/mathml+xml",
    "mbox"    => "application/mbox",
    "mdoc"    => "text/troff",
    "me"      => "text/troff",
    "mid"     => "audio/midi",
    "midi"    => "audio/midi",
    "mime"    => "message/rfc822",
    "mml"     => "application/mathml+xml",
    "mng"     => "video/x-mng",
    "mov"     => "video/quicktime",
    "mp3"     => "audio/mpeg",
    "mp4"     => "video/mp4",
    "mp4v"    => "video/mp4",
    "mpeg"    => "video/mpeg",
    "mpg"     => "video/mpeg",
    "ms"      => "text/troff",
    "msi"     => "application/x-msdownload",
    "odp"     => "application/vnd.oasis.opendocument.presentation",
    "ods"     => "application/vnd.oasis.opendocument.spreadsheet",
    "odt"     => "application/vnd.oasis.opendocument.text",
    "ogg"     => "application/ogg",
    "ogv"     => "video/ogg",
    "p"       => "text/x-pascal",
    "pas"     => "text/x-pascal",
    "pbm"     => "image/x-portable-bitmap",
    "pdf"     => "application/pdf",
    "pem"     => "application/x-x509-ca-cert",
    "pgm"     => "image/x-portable-graymap",
    "pgp"     => "application/pgp-encrypted",
    "pkg"     => "application/octet-stream",
    "pl"      => "text/x-script.perl",
    "pm"      => "text/x-script.perl-module",
    "png"     => "image/png",
    "pnm"     => "image/x-portable-anymap",
    "ppm"     => "image/x-portable-pixmap",
    "pps"     => "application/vnd.ms-powerpoint",
    "ppt"     => "application/vnd.ms-powerpoint",
    "ps"      => "application/postscript",
    "psd"     => "image/vnd.adobe.photoshop",
    "py"      => "text/x-script.python",
    "qt"      => "video/quicktime",
    "ra"      => "audio/x-pn-realaudio",
    "rake"    => "text/x-script.ruby",
    "ram"     => "audio/x-pn-realaudio",
    "rar"     => "application/x-rar-compressed",
    "rb"      => "text/x-script.ruby",
    "rdf"     => "application/rdf+xml",
    "roff"    => "text/troff",
    "rpm"     => "application/x-redhat-package-manager",
    "rss"     => "application/rss+xml",
    "rtf"     => "application/rtf",
    "ru"      => "text/x-script.ruby",
    "s"       => "text/x-asm",
    "sgm"     => "text/sgml",
    "sgml"    => "text/sgml",
    "sh"      => "application/x-sh",
    "sig"     => "application/pgp-signature",
    "snd"     => "audio/basic",
    "so"      => "application/octet-stream",
    "svg"     => "image/svg+xml",
    "svgz"    => "image/svg+xml",
    "swf"     => "application/x-shockwave-flash",
    "t"       => "text/troff",
    "tar"     => "application/x-tar",
    "tbz"     => "application/x-bzip-compressed-tar",
    "tcl"     => "application/x-tcl",
    "tex"     => "application/x-tex",
    "texi"    => "application/x-texinfo",
    "texinfo" => "application/x-texinfo",
    "text"    => "text/plain",
    "tif"     => "image/tiff",
    "tiff"    => "image/tiff",
    "torrent" => "application/x-bittorrent",
    "tr"      => "text/troff",
    "txt"     => "text/plain",
    "vcf"     => "text/x-vcard",
    "vcs"     => "text/x-vcalendar",
    "vrml"    => "model/vrml",
    "war"     => "application/java-archive",
    "wav"     => "audio/x-wav",
    "wma"     => "audio/x-ms-wma",
    "wmv"     => "video/x-ms-wmv",
    "wmx"     => "video/x-ms-wmx",
    "wrl"     => "model/vrml",
    "wsdl"    => "application/wsdl+xml",
    "xbm"     => "image/x-xbitmap",
    "xhtml"   => "application/xhtml+xml",
    "xls"     => "application/vnd.ms-excel",
    "xml"     => "application/xml",
    "xpm"     => "image/x-xpixmap",
    "xsl"     => "application/xml",
    "xslt"    => "application/xslt+xml",
    "yaml"    => "text/yaml",
    "yml"     => "text/yaml",
    "zip"     => "application/zip",

The most common ones are already defined.

=head1 ATTRIBUTES

L<Mojolicious::Types> implements the following attributes.

=head2 C<types>

  my $map = $types->types;
  $types  = $types->types({png => 'image/png'});

List of MIME types.

=head1 METHODS

L<Mojolicious::Types> inherits all methods from L<Mojo::Base> and implements
the following ones.

=head2 C<detect>

    my $exts = $types->detect('application/json;q=9');
    my $exts = $types->detect('text/html, application/json;q=9', 1);

Detect file extensions from C<Accept> header value, prioritization of
unspecific values that contain more than one MIME type is disabled by default.

    # List detected extensions prioritized
    say for @{$types->detect('application/json, text/xml;q=0.1', 1)};

=head2 C<type>

    my $type = $types->type('png');
    $types   = $types->type(png => 'image/png');
    $types   = $types->type(json => [qw(application/json text/x-json)]);

Get or set MIME types for file extension, alternatives are only used for
detection.

=head2 C<type_by_path>

Detect MIME type out of path name.

    my $mime = $types->type_by_path('/path/to/file.css') # text/css

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
