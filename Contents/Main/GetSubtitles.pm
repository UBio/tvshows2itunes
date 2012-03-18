#
#  GetSubtitles
#
#  Created by Eduardo Andrés León on 2012-03-18.
#  Copyright (c) 2012 CNIO. All rights reserved.
#

package Contents::Main::GetSubtitles;
use strict;
use lib '/usr/bin/Contents/lib/Library/Perl/Updates/5.12.3/';
use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;
use lib '/usr/bin/Contents/lib/perl5/site_perl/';
use RPC::XML;
use lib '/usr/bin/Contents/lib/';
require RPC::XML::Client;

my $cli;
my $TVShow2iTunes->{login};
my $TVShow2iTunes->{ua};

sub new{
	my ($class,$TVShow2iTunes)=@_;
	my $this={};
	bless($this);
	return($this);
}
=head2 GetSubtitles

  Example    : 
  Description: This method returns a string that is considered to be
               the 'display' identifier.
  Returntype : String
  Exceptions : none
  Caller     : web drawing code
  Status     : Stable

=cut
sub login{
	my ($subtitles,$TVShow2iTunes)=@_;
	$TVShow2iTunes->{ua}= LWP::UserAgent->new();
	my $useragent=$TVShow2iTunes->{ua}->agent($TVShow2iTunes->{app_name});
	$cli = RPC::XML::Client->new('http://api.opensubtitles.org/xml-rpc');
	if($cli->send_request('ServerInfo')){
		$TVShow2iTunes->{login}=$cli->send_request('LogIn',("","","eng"),$TVShow2iTunes->{ua}->agent($TVShow2iTunes->{app_name}));
		# Login failed?
	    if ( ! defined($TVShow2iTunes->{login}) )
	    {
	        print STDERR "ERROR :: ";
	        print $RPC::XML::ERROR, "\n";
	        exit(0);
	    }
	}
	
	return();
}
# 
sub logout{
	my ($subtitles,$TVShow2iTunes)=@_;
	$TVShow2iTunes->{login}=$cli->send_request('LogOut',$TVShow2iTunes->{login}->{token}->value);
	return();
}
# 
sub GetSubtitles{
	my $TVShow2iTunes=shift;	
	my $filename=$TVShow2iTunes->{input};
	my @imdbs;
	my @lang=("eng,spa");
	my $all_lang;
	my $sortedSub;
	my $videoSRT;
	my $convert=undef;
	my @srtfiles;
	my $ISO639;
	my @movienames;
	@srtfiles="";
	my $size = -s $filename;
	
	my $hash=OpenSubtitlesHash($TVShow2iTunes);
	my @local_lang;
	foreach my $language (@lang){
		my @split=split(/,/,$language);
		for (my $var = 0; $var<=$#split; $var++) {
			push @local_lang,$split[$var];
		}
	}
	
	foreach my $language (@local_lang){
		my $localSRT=$filename . "." . $TVShow2iTunes->{ISO639}->{$language} . ".srt";
		if(-e $localSRT){
			print "WARN :: Local Sutbtitles already found at $localSRT\n";
			delete $lang[$language];
			$ISO639->{$localSRT}=$language;
			push (@srtfiles,$localSRT);
		}
	}
	
	
	foreach my $language (@lang){
		my $result;
		if($TVShow2iTunes->{login}->{token}->value){
			$result =$cli->send_request('SearchSubtitles',$TVShow2iTunes->{login}->{token}->value,[{ sublanguageid => $language,moviehash => $hash, moviebytesize => $size}]);
		}
		my $rootname=substr($filename, rindex($filename,"/")+1,length($filename)-rindex($filename,"/")-1);
		# Stop if xml-rpc request failed
		# print $result->{data} ."------\n";
		if ( ! defined($result) )
		{
		    print "--> Search failed!\n";
		    print $RPC::XML::ERROR, "\n";
		    exit(0);
		}
		else
		{
			print "LOG :: Searching subtitles for $language\n";
			my $imdb;
			my $array_ref;
			my $req_data = $result->{data};
			my $result_count=0;
			# print "localSRT es $localSRT\n";

			if(uc(ref($req_data)) =~ "ARRAY"){
				$result_count=scalar(@$req_data);
			}
		    print "LOG :: Found $result_count file for $language\n";
			my $maxCount=0;
			if($result_count>0){
				#More than one result, get the most downloaded one!
				foreach my $subtitle_info ( @{$result->{data}} ){
					foreach my $a (keys %{$subtitle_info}){
						$sortedSub->{$language}->{$subtitle_info->{SubDownloadsCnt}->value}->{$a}=$subtitle_info->{$a};
						#order by downloadCount
						if($maxCount< $subtitle_info->{SubDownloadsCnt}->value){
							$maxCount=$subtitle_info->{SubDownloadsCnt}->value;
						}
					}
				}
			}
			else{
				#$videoSRT=undef;
				return(0); 
			}
			#Max downlaoded SubDownloadsCnt
			my $cont=0;
			foreach my $subtitle_info ( keys %{$sortedSub->{$language}->{$maxCount}} )
			{
				$videoSRT->{$subtitle_info}=$sortedSub->{$language}->{$maxCount}->{$subtitle_info};
			}
			my $gzfilename=$filename. "." .  $sortedSub->{$language}->{$maxCount}->{ISO639}->value . "." . $sortedSub->{$language}->{$maxCount}->{SubFormat}->value .".gz";
			my $srtfilename=$filename. "." .  $sortedSub->{$language}->{$maxCount}->{ISO639}->value . "." . $sortedSub->{$language}->{$maxCount}->{SubFormat}->value;
			push (@srtfiles,$srtfilename) if($srtfilename);
			$ISO639->{$srtfilename}=$sortedSub->{$language}->{$maxCount}->{ISO639}->value if ($srtfilename);
			if(-e $srtfilename){
				print "WARN :: Sutbtitles already found at $srtfilename\n";
				last;
			}
			else{
				my $response = $TVShow2iTunes->{ua}->get( $sortedSub->{$language}->{$maxCount}->{SubDownloadLink}->value,':content_file' => $gzfilename);
				die "Can't get " . $sortedSub->{$language}->{$maxCount}->{SubDownloadLink}->value."  -- ", $response->status_line unless $response->is_success;
				my $status = gunzip $gzfilename => $srtfilename or die "gunzip failed: $GunzipError\n";
				unlink($gzfilename);
				if($language eq "eng"){
					$videoSRT->{Season}=$sortedSub->{$language}->{$maxCount}->{SeriesSeason};
					$videoSRT->{Episode}=$sortedSub->{$language}->{$maxCount}->{SeriesEpisode};
					$videoSRT->{MovieName}=$sortedSub->{$language}->{$maxCount}->{MovieName};
					push @imdbs, $sortedSub->{$language}->{$maxCount}->{IDMovieImdb}->value;
					push @movienames,$sortedSub->{$language}->{$maxCount}->{MovieName};
				}
			}
		}
	}
	$TVShow2iTunes->{imdbs}=\@imdbs;
	$TVShow2iTunes->{movienames}=\@movienames;
}

sub OpenSubtitlesHash {
	my ($TVShow2iTunes)=shift;
	my $filename=$TVShow2iTunes->{input};
        open my $handle, "<", $filename or die $!;
        binmode $handle;

        my $fsize = -s $filename;

        my $hash = [$fsize & 0xFFFF, ($fsize >> 16) & 0xFFFF, 0, 0];

        $hash = AddUINT64($hash, ReadUINT64($handle)) for (1..8192);

    my $offset = $fsize - 65536;
    seek($handle, $offset > 0 ? $offset : 0, 0) or die $!;

    $hash = AddUINT64($hash, ReadUINT64($handle)) for (1..8192);

    close $handle or die $!;
    return UINT64FormatHex($hash);
}
sub ReadUINT64 {
        read($_[0], my $u, 8);
        return [unpack("vvvv", $u)];
}
sub AddUINT64 {
    my $o = [0,0,0,0];
    my $carry = 0;
    for my $i (0..3) {
        if (($_[0]->[$i] + $_[1]->[$i] + $carry) > 0xffff ) {
                        $o->[$i] += ($_[0]->[$i] + $_[1]->[$i] + $carry) & 0xffff;
                        $carry = 1;
                } else {
                        $o->[$i] += ($_[0]->[$i] + $_[1]->[$i] + $carry);
                        $carry = 0;
                }
        }
    return $o;
}
sub UINT64FormatHex {
    return sprintf("%04x%04x%04x%04x", $_[0]->[3], $_[0]->[2], $_[0]->[1], $_[0]->[0]);
}


1;
# =head1 NAME
# 
#  GetSubtitles
# 
# =head1 SYNOPSIS
# 
# Description for  GetSubtitles
# 
