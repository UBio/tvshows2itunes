#
#  transcode
#
#  Created by Eduardo Andrés León on 2012-03-18.
#  Copyright (c) 2012 . All rights reserved.
#

package Contents::Main::Transcode;
use Contents::Main::GetSubtitles;
use strict;
sub new{
	my ($class,%args)=@_;
	my $this={};
	bless($this);
	return($this);
}
=head2 TVShows2iTunes->{transcode}

  Example    : 
  Description: This method returns a string that is considered to be
               the 'display' identifier.
  Returntype : String
  Exceptions : none
  Caller     : web drawing code
  Status     : Stable

=cut

sub Recoding{
	my ($TVShows2iTunes)=shift;	
	my $convert=undef;
	my @srtfiles;
	my $ISO639;
	my @movienames;
		
	$TVShows2iTunes->{transcode}|| "iPad";
	my $SubtitlesFile=shift;
	my $outputfilename = substr $TVShows2iTunes->{input}, 0, rindex( $TVShows2iTunes->{input}, q{.} );
	$outputfilename.="_".$TVShows2iTunes->{transcode}.".m4v";
	$TVShows2iTunes->{outputfilename}=$outputfilename;
	my $movieName;
	if(-e $outputfilename) {
		print "WARN :: The output file $outputfilename already exists\n";
		return();
	}
	else{
		$outputfilename=quotemeta($outputfilename);
		if($TVShows2iTunes->{ShortName} =~ /\.mkv$/){
			my ($videoS,$audio)=getStreams($TVShows2iTunes->{input});
			$convert=1;
			$TVShows2iTunes->{input}=quotemeta $TVShows2iTunes->{input};
			my $ac3file="$TVShows2iTunes->{input}.ac3";
			my $h264file="$TVShows2iTunes->{input}.h264";
			my $aacfile="$TVShows2iTunes->{input}.aac";

			my $Video_cmd="/usr/bin/Contents/bin/mkvextract tracks $TVShows2iTunes->{input} ".$videoS->{id}.":$h264file &>/dev/null";
		
			my $audio_cmd;
			if($audio->{Format} eq "Digital Theater Systems"){
				print "LOG :: ".$audio->{Format} . " Found, coverting to AC3 5.1\n";
				$audio_cmd="/usr/bin/Contents/bin/mencoder $TVShows2iTunes->{input} -aid 0 -ovc copy -oac lavc -lavcopts acodec=ac3:abitrate=320 -channels 6 -af pan=6:0:1:0:0:0:0:0:0:0:0:1:0:0:0:0:0:0:1:0:0:1:0:0:0:1:0:0:0:0:0:0:0:0:1:0:0 -srate $audio->{Sampling_rate}000 -of rawaudio -o $ac3file &>/dev/null";
			}else{
				$audio_cmd="/usr/bin/Contents/bin/mkvextract tracks $TVShows2iTunes->{input} ".$audio->{id}.":$ac3file &>/dev/null";
			}
			my $audio_cmd_convert="/usr/bin/Contents/bin/mencoder $TVShows2iTunes->{input} -aid 0 -ovc copy -oac faac -faacopts br=160:mpeg=4:object=2 -channels $audio->{Channel} -srate $audio->{Sampling_rate}000 -of rawaudio -o $aacfile &>/dev/null" if ($convert);
			my $m4v_cmd;
			my $check=undef;
			my $device;
			if($SubtitlesFile eq "NO"){
				$check++;
				$movieName=$TVShows2iTunes->{input};
				if(scalar(@srtfiles)>0){
					my $subtitleSentence;
					my $NumeberofId=3;
					foreach my $srtfile(@srtfiles){
						if($srtfile){
							$NumeberofId++;
							$subtitleSentence.="-add $srtfile#1:lang=".$ISO639->{$srtfile}.":group=2:disable ";
						}
					}
					my $device;
					if(lc($TVShows2iTunes->{transcode}) eq "ipad" or lc($TVShows2iTunes->{transcode}) eq "iphone"){ $device="-ipod";}
					$m4v_cmd ="/usr/bin/Contents/bin/mp4box -add $TVShows2iTunes->{input}\.h264:lang=$audio->{language} -add $TVShows2iTunes->{input}\.ac3:lang=$audio->{language} $subtitleSentence -add $TVShows2iTunes->{input}\.aac:lang=".$audio->{language}." -disable 2 -group-add trackId=2:trackId=$NumeberofId -keepall $device -new -fps $videoS->{Frate} $outputfilename &>/dev/null";				
					
				}else{
					if(lc($TVShows2iTunes->{transcode}) eq "ipad" or lc($TVShows2iTunes->{transcode}) eq "iphone"){ $device="-ipod";}                                                                                                                                                                                           
						$m4v_cmd ="/usr/bin/Contents/bin/mp4box -add $TVShows2iTunes->{input}\.h264:lang=$audio->{language} -add $TVShows2iTunes->{input}\.ac3:lang=$audio->{language} -add $TVShows2iTunes->{input}\.aac:lang=".$audio->{language}." -keepall $device -new -fps $videoS->{Frate} $outputfilename &>/dev/null";
					}
			}
			else{
				$movieName=${$TVShows2iTunes->{movienames}}[0]->value;
				#Notifing to the user;
				#`bin/growlnotify -m "Converting  $movieName"`;
				my $subtitleSentence;
				my $NumeberofId=3;
				foreach my $srtfile(@srtfiles){
					if($srtfile){
						$NumeberofId++;
						$subtitleSentence.="-add $srtfile#1:lang=".$ISO639->{$srtfile}.":group=2:disable ";
					}
				}
				my $device;
				if(lc($TVShows2iTunes->{transcode}) eq "ipad" or lc($TVShows2iTunes->{transcode}) eq "iphone"){ $device="-ipod";}
				$m4v_cmd ="/usr/bin/Contents/bin/mp4box -add $TVShows2iTunes->{input}\.h264:lang=$audio->{language} -add $TVShows2iTunes->{input}\.ac3:lang=$audio->{language} $subtitleSentence -add $TVShows2iTunes->{input}\.aac:lang=".$audio->{language}." -disable 2 -group-add trackId=2:trackId=$NumeberofId -keepall $device -new -fps $videoS->{Frate} $outputfilename &>/dev/null";				
			}
				#print "$Video_cmd\n$audio_cmd\n$audio_cmd_convert\n$m4v_cmd\n";
				print "LOG :: Extracting H.264 file\n";
				system($Video_cmd);
				print "LOG :: Extracting Audio file\n";
				system($audio_cmd);
				print "LOG :: Extracting Audio ACC file\n";
				system($audio_cmd_convert);
				print "LOG :: Creation of m4v file for $TVShows2iTunes->{transcode}\n";
				system($m4v_cmd);
				system("rm $ac3file");
				system("rm $h264file");
				system("rm $aacfile");
				
				Contents::Main::IMDB::MetaData($TVShows2iTunes) if(!defined($check));
		
		}else{
			print STDERR "ERROR :: At this moment only mkv files can be transcoded (".$TVShows2iTunes->{ShortName}.")\n";
			return();
		}
	}
}


sub getStreams{
	my $TVShows2iTunes->{input}=shift;
	$TVShows2iTunes->{input}=quotemeta($TVShows2iTunes->{input});
	my $log_file="/tmp/.$$\.log" . ".log";
	system("/usr/bin/Contents/bin/mediainfo $TVShows2iTunes->{input} --LogFile=$log_file --Output=XML 0 1 2 > /dev/null");
	my $Sampling_rate;
	my $audio;	
	my $videoS;	
	my $type;
	my $id;
	my $Bdepth;
	my $language;
	my $Codec_ID;
	my $Channel;
	my $Format;
	open(XML,$log_file) || die "$! ($log_file)";
	while(my $line=<XML>){
		chomp($line);
		if($line =~ /^<\/track>/){
			if($type and $id and $Bdepth and $language and $Codec_ID and $Sampling_rate and $Channel and $Format){
				#print "//\nType $type\nID $id\nBdepth $Bdepth\nLangage $language\nCodec_ID $Codec_ID\nSampling_rate $Sampling_rate\nChannel $Channel\n//\n";
				$audio->{type}=$type;
				$audio->{Bdepth}=$Bdepth;
				$audio->{Codec_ID}=$Codec_ID;
				$audio->{language}=$language;
				$audio->{Channel}=$Channel;
				$audio->{id}=$id;
				$audio->{Sampling_rate}=$Sampling_rate;
				$audio->{Format}=$Format;
			}
			next;
		}
		elsif($line =~ /^<track type="Audio"/){
			$type="Audio";
		}
		elsif($line =~ /<ID>(\d+)<\/ID>/ ){
			$id=$1;
		}
		elsif($line =~ /<Format_Info>(.+)<\/Format_Info>/){
			$Format=$1;
		}
		elsif($line =~ /<Bit_depth>(\d+) bits<\/Bit_depth>/ ){
			$Bdepth=$1;
		}elsif($line =~ /<Language>(\w+)<\/Language>/ ){
			$language=$1;
		}elsif($line =~ /<Codec_ID>(.+)<\/Codec_ID>/){
			$Codec_ID=$1;
		}elsif($line =~ /<Sampling_rate>(\d+)\.0 KHz<\/Sampling_rate>/){
			$Sampling_rate=$1;
		}elsif($line =~ /<Channel_s_>(\d+) channels<\/Channel_s_>/){
			$Channel=$1;
		}elsif($line =~ /<track type="Video">/ ){
			next;
		}
	}
	close XML;
	my $type;
	my $id;
	my $FProfile;
	my $Frate;
	open(XML,$log_file) || die "$!";
	while(my $line=<XML>){
		chomp($line);
		if($line =~ /^<\/track>/){
			if($type and $id and $FProfile and $Frate){
				$videoS->{type}=$type;
				$videoS->{FProfile}=$FProfile;
				$videoS->{Frate}=$Frate;
				$videoS->{id}=$id;
				return($videoS,$audio);
			}
			next;
		}
		elsif($line =~ /^<track type="Video"/){
			$type="Video";
		}
		elsif($line =~ /<ID>(\d+)<\/ID>/ ){
			$id=$1;
		}elsif($line =~ /<Format_profile>(.+)<\/Format_profile>/ ){
			$FProfile=$1;
		}elsif($line =~ /<Frame_rate>(.+) fps<\/Frame_rate>/ ){
			$Frate=$1;
		}elsif($line =~ /<track type="Audio">/ ){
			next;
		}
	}
	close XML;
	unlink($log_file);	
}

1;
=head1 NAME

 TVShows2iTunes->{transcode}

=head1 SYNOPSIS

Description for  TVShows2iTunes->{transcode}

