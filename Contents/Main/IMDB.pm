#
#  IMDB
#
#  Created by Eduardo Andrés León on 2012-03-18.
#  Copyright (c) 2012 CNIO. All rights reserved.
#

package Contents::Main::IMDB;
use strict;
use XML::Simple;

my $videoSRT;
sub new{
	my ($class,%args)=@_;
	my $this={};
	bless($this);
	return($this);
}
=head2 IMDB

  Example    : 
  Description: This method returns a string that is considered to be
               the 'display' identifier.
  Returntype : String
  Exceptions : none
  Caller     : web drawing code
  Status     : Stable

=cut

sub getMetaDataIMDBAPI{
	my ($subtitles,$TVShow2iTunes)=@_;
	if(${$TVShow2iTunes->{imdbs}}[0]>1){
		my $tmp_file="/tmp/\.".${$TVShow2iTunes->{imdbs}}[0]."\_$$.xml";
		if(${$TVShow2iTunes->{imdbs}}[0]>1){
			my $url="http://www.imdbapi.com/?i=tt".${$TVShow2iTunes->{imdbs}}[0]."&t=&r=XML&plot=full";
			my $response = $TVShow2iTunes->{ua}->get($url,':content_file' => $tmp_file);
			if(-s $tmp_file >26 and defined $response){
				my $data = XMLin($tmp_file);
				my @artworkName=split(/\//,$data->{movie}->{poster});
				my $artworkFile="/tmp/".$artworkName[$#artworkName];
				my $response = $TVShow2iTunes->{ua}->get( $data->{movie}->{poster},':content_file' => $artworkFile);
			         die "Can't get " . $artworkName[$#artworkName]."  -- ", $response->status_line unless $response->is_success;
				foreach my $a (keys %{$data->{movie}}){
					$TVShow2iTunes->{$a}=$data->{movie}->{$a};
					# print $a ."\t" . $data->{movie}->{$a} ."\n";
				}
				$TVShow2iTunes->{cover}=$artworkFile;
			}
			else{
				print STDERR "ERROR :: IMDB_API seems Down, some metadata will be unavailable\n";
				return();
			}
		}else{
			print STDERR "ERROR :: Wrong IMDBiD\n";
			exit;
		}
		unlink($tmp_file);
	}
	else{
		return();
	}
}


sub MetaData{
	my ($TVShows2iTunes)=shift;

	my $showName;
	my %videoSRT=$TVShows2iTunes->{videoSRT};
	if($TVShows2iTunes->{videoSRT}{MovieName}->value =~ /\"/){
		$showName=$TVShows2iTunes->{videoSRT}{MovieName}->value;
		$showName=~ s/\"//g;
		$showName=~ s/$TVShows2iTunes->{title}//g;
		$showName=~ s/\s+$//g;
		
	}
	else{
		$showName=$TVShows2iTunes->{videoSRT}{MovieName}->value;
	}
	
	my $cmd="/usr/bin/Contents/bin/AtomicParsley " . quotemeta($TVShows2iTunes->{outputfilename})." --overWrite ";
	$cmd .="--artwork ". $TVShows2iTunes->{cover}." ";
	$cmd .="--TVShowName \"".$showName."\" ";
	$cmd .="--stik \"TV Show\" ";
	$cmd .="--TVEpisode \" ".$TVShows2iTunes->{videoSRT}{Episode}->value."\" ";
	$cmd .="--TVSeasonNum \" ".$TVShows2iTunes->{videoSRT}{Season}->value."\" ";
	$cmd .="--title \"".$TVShows2iTunes->{title}."\" ";
	$cmd .="--genre \"".$TVShows2iTunes->{genre}."\" ";
	$cmd .="--comment \"".$TVShows2iTunes->{plot}."\" ";
	$cmd .="--year \"".$TVShows2iTunes->{year}."\" ";
	$cmd .="--description \"".$TVShows2iTunes->{plot}."\" ";
	#print "Atomic:: $cmd\n\n";
	print "LOG :: Adding Metadata !\n";
	system("$cmd &>/dev/null");
	#system("$cmd");
	unlink($TVShows2iTunes->{cover});
	return();
}
sub getMetaDataIMDBPERL{
	my ($subtitles,$TVShow2iTunes)=@_;
	
	my $imdb=shift;
	if($imdb>1){
		print "IMDB :: $imdb\n";
    	my $imdbObj = new IMDB::Film(crit => $imdb);
        if($imdbObj->status) {
                print "Title: ".$imdbObj->title()."\n";
                print "Year: ".$imdbObj->year()."\n";
                print "Plot Symmary: ".$imdbObj->plot()."\n";
                print "Cover: ".$imdbObj->poster()."\n";
				print "Summary: " . $imdbObj->storyline() . "\n";
				#print "TVShow: " . $imdbObj->episodeof()->[0] . "\n";
				print Dumper($imdbObj->episodeof());
				foreach $b (keys %{$imdbObj->episodeof()}){
					print "TVShow: " . $b ."\n";
				}
				foreach my $a (keys %{$imdbObj}){
					print $a ."\t" . $imdbObj->$a ."\n";
				}
        } else {
                print "Something wrong: ".$imdbObj->error;
        }
	}
}

sub getMetaDataOpen{
	my ($subtitles,$TVShow2iTunes)=@_;
	
	if(${$TVShow2iTunes->{imdbs}}[0]>1){
		#my $cli = RPC::XML::Client->new('http://api.opensubtitles.org/xml-rpc');
		if($TVShow2iTunes->{cli}->send_request('ServerInfo')){
			my $TVShow2iTunes->{login}=$TVShow2iTunes->{cli}->send_request('LogIn',("","","eng"),$TVShow2iTunes->{ua}->agent($TVShow2iTunes->{app_name}));
			my $resultIMDB =$TVShow2iTunes->{cli}->send_request('GetIMDBMovieDetails',$TVShow2iTunes->{login}->{token}->value,${$TVShow2iTunes->{imdbs}}[0]);
			print Dumper($resultIMDB);
		}
	}
}

#

1;
=head1 NAME

 IMDB

=head1 SYNOPSIS

Description for  IMDB

