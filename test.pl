#!/usr/bin/env perl

use strict;
use warnings;
use Mojo::UserAgent;
use Data::Dumper;

my $a = Mojo::UserAgent->new();
my $tx = $a->post('http://html5.validator.nu/?out=json', {'content-type' => 'text/html; charset=UTF-8'}, html());
#warn Dumper $tx->req->to_string;
warn Dumper $tx->res;

sub html {
    return <<'EOF';
<!DOCTYPE html>
<html> 
	<head> 
	<title>My Page</title> 
	<meta name="viewport" content="width=device-width, initial-scale=1" />
	<link rel="stylesheet" href="http://code.jquery.com/mobile/1.0/jquery.mobile-1.0.min.css" />
	<script type="text/javascript" src="http://code.jquery.com/jquery-1.6.4.min.js"></script>
	<script type="text/javascript" src="http://code.jquery.com/mobile/1.0/jquery.mobile-1.0.min.js"></script>
</head>
<a>
<body> 

<div data-role="page">

	<div data-role="header">
		<h1>My Title</h1>
	</div><!-- /header -->

	<div data-role="content">	
		<p>Hello world</p>
		<ul data-role="listview" data-inset="true" data-filter="true">
			<li><a href="#">Acura</a></li>
			<li><a href="#">Audi</a></li>
			<li><a href="#">BMW</a></li>
			<li><a href="#">Cadillac</a></li>
			<li><a href="#">Ferrari</a></li>
		</ul>
		<form>
			<label for="slider-0">Input slider:</label>
			<input type="range" name="slider" id="slider-0" value="25" min="0" max="100"  />
		 </form>
	</div><!-- /content -->

</div><!-- /page -->

</body>
</html>
EOF

}