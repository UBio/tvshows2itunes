#
#  transcode
#
#  Created by Eduardo Andrés León on 2012-03-18.
#  Copyright (c) 2012 . All rights reserved.
#

package Contents::Main::Transcode;
use Contents::Main::GetSubtitles;
use lib '/usr/bin/Contents/lib/';
use XML::Simple;
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
	my $srtfiles=$TVShows2iTunes->{srtfiles};
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
		if($TVShows2iTunes->{ShortName} =~ /\.mkv$/ or $TVShows2iTunes->{ShortName} =~ /\.avi$/){

			$TVShows2iTunes->{Streams}=getStreams($TVShows2iTunes->{input});
			$convert=1;
			$TVShows2iTunes->{input}=quotemeta $TVShows2iTunes->{input};
			
			my $ac3file="$TVShows2iTunes->{input}.ac3";
			my $h264file="$TVShows2iTunes->{input}.h264";
			my $aacfile="$TVShows2iTunes->{input}.aac";
			my $avidumped="$TVShows2iTunes->{input}.avidumped.v.avi";
			my $Video_cmd;
			#####Video stuff##############

			# if($TVShows2iTunes->{Streams}->{MEDIA}->{General}->{Format} eq "AVI"){
			# 	print "LOG :: ".$TVShows2iTunes->{Streams}->{MEDIA}->{General}->{Format} . " is not compatible, it must be converted into h264\n";
			# 	$Video_cmd="/usr/bin/Contents/bin/mencoder $TVShows2iTunes->{input} -vf harddup -ovc x264 -x264encopts threads=auto:bitrate=$TVShows2iTunes->{Streams}->{MEDIA}->{Video}->{Bit_rate}:level_idc=31:bframes=0:nocabac -nosound -of rawvideo -noautoexpand -o $h264file";
			# }
			if($TVShows2iTunes->{Streams}->{MEDIA}->{Video}->{Format} eq "MPEG-4 Visual" or $TVShows2iTunes->{Streams}->{MEDIA}->{Video}->{Format} eq "AVI" or $TVShows2iTunes->{Streams}->{MEDIA}->{Video}->{Format} eq "Audio Video Interleave"){
				print "LOG :: ".$TVShows2iTunes->{Streams}->{MEDIA}->{Video}->{Format} . " Found, transcoding into h264 (it'll take a while)\n";
				#extracting MP4 stream into avi
				$Video_cmd="/usr/bin/Contents/bin/mencoder $TVShows2iTunes->{input} -vf harddup -ovc x264 -x264encopts threads=auto:bitrate=$TVShows2iTunes->{Streams}->{MEDIA}->{Video}->{Bit_rate}:level_idc=31:bframes=0:nocabac -nosound -of rawvideo -noautoexpand -o $h264file";
			}else{
				print "LOG :: ".$TVShows2iTunes->{Streams}->{MEDIA}->{Video}->{Format} . " Found, coverting to h264\n";
				$Video_cmd="/usr/bin/Contents/bin/mkvextract tracks $TVShows2iTunes->{input} ".$TVShows2iTunes->{Streams}->{MEDIA}->{Video}->{ID}.":$h264file";
			}
			#########################
			
			my $audio_cmd;
			my $audio_cmd_convert;
			if($TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Format} eq "Digital Theater Systems"){
				print "LOG :: ".$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Format} . " Found, coverting to AC3 5.1\n";
				#converting from DTS to AC 5.1
				$audio_cmd="/usr/bin/Contents/bin/mencoder $TVShows2iTunes->{input} -aid $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{ID} -ovc copy -oac lavc -lavcopts acodec=ac3:abitrate=320 -channels 6 -af pan=6:0:1:0:0:0:0:0:0:0:0:1:0:0:0:0:0:0:1:0:0:1:0:0:0:1:0:0:0:0:0:0:0:0:1:0:0 -srate $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Sampling_rate}000 -of rawaudio -o $ac3file";
				#Creating the Stereo track
				$audio_cmd_convert="/usr/bin/Contents/bin/mencoder $TVShows2iTunes->{input} -aid $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{ID} -ovc copy -oac faac -faacopts br=160:mpeg=4:object=2 -channels $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Channel_s_} -srate $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Sampling_rate}000 -of rawaudio -o $aacfile" if ($convert);
			}
			elsif($TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Format} eq "Audio Coding 3"  or $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Format} eq "MPEG Audio" or $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Format} eq "AC-3"){
				print "LOG :: ".$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Format} . " Stereo Found, No coverting to AC3 5.1\n";
				#extracting the Stereo track
				$audio_cmd_convert="/usr/bin/Contents/bin/mencoder $TVShows2iTunes->{input} -aid $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{ID} -ovc copy -oac faac -faacopts br=160:mpeg=4:object=2 -channels $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Channel_s_} -srate $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Sampling_rate}000 -of rawaudio -o $aacfile" if ($convert);
			}
			else{
				#Extracting the AC3 5.1 tracks
				$audio_cmd="/usr/bin/Contents/bin/mkvextract tracks $TVShows2iTunes->{input} ".$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{ID}.":$ac3file &>/dev/null";
				#Creating the Stereo track
				$audio_cmd_convert="/usr/bin/Contents/bin/mencoder $TVShows2iTunes->{input} -aid $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{ID} -ovc copy -oac faac -faacopts br=160:mpeg=4:object=2 -channels $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Channel_s_} -srate $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Sampling_rate}000 -of rawaudio -o $aacfile" if ($convert);
				
			}
			my $m4v_cmd;
			my $check=undef;
			my $device;
			if($SubtitlesFile eq "NO"){
				$check++;
				$movieName=$TVShows2iTunes->{input};
				if(scalar(keys %{$srtfiles})>0){
					my $subtitleSentence;
					my $NumeberofId=3;
					foreach my $srtfile(keys %{$srtfiles}){
						if($srtfile){
							$NumeberofId++;
							my $lang=$TVShows2iTunes->{SRT_ISO639}->{$srtfile};
							$srtfile=quotemeta($srtfile);
							$subtitleSentence.="-add $srtfile#1:lang=$lang:group=2:disable ";
						}
					}
					my $device;
					if(lc($TVShows2iTunes->{transcode}) eq "ipad" or lc($TVShows2iTunes->{transcode}) eq "iphone"){ $device="-ipod";}
					$m4v_cmd ="/usr/bin/Contents/bin/mp4box -add $TVShows2iTunes->{input}\.h264:lang=$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language} -add $TVShows2iTunes->{input}\.ac3:lang=$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language} $subtitleSentence -add $TVShows2iTunes->{input}\.aac:lang=".$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language}." -disable 2 -group-add trackId=2:trackId=$NumeberofId -keepall $device -new -fps $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language} $outputfilename";				
					
				}else{
					if(lc($TVShows2iTunes->{transcode}) eq "ipad" or lc($TVShows2iTunes->{transcode}) eq "iphone"){ $device="-ipod";}                                                                                                                                                                                           
						$m4v_cmd ="/usr/bin/Contents/bin/mp4box -add $TVShows2iTunes->{input}\.h264:lang=$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language} -add $TVShows2iTunes->{input}\.ac3:lang=$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language} -add $TVShows2iTunes->{input}\.aac:lang=".$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language}." -keepall $device -new -fps $TVShows2iTunes->{Streams}->{MEDIA}->{Video}->{Frate} $outputfilename";
					}
			}
			else{
				#Notifing to the user;
				#`bin/growlnotify -m "Converting  $movieName"`;
				my $subtitleSentence;
				my $NumeberofId=3;
				foreach my $srtfile(keys %{$srtfiles}){
					if($srtfile){
						$NumeberofId++;
						my $lang=$TVShows2iTunes->{SRT_ISO639}->{$srtfile};
						$srtfile=quotemeta($srtfile);
						$subtitleSentence.="-add $srtfile#1:lang=$lang:group=2:disable ";
					}
				}
				my $device;
				if(lc($TVShows2iTunes->{transcode}) eq "ipad" or lc($TVShows2iTunes->{transcode}) eq "iphone"){ $device="-ipod";}
				if($TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Format} eq "Audio Coding 3" or $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Format} eq "MPEG Audio" or $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Format} eq "Audio Video Interleave" or $TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Format} eq "AC-3"){
					#$m4v_cmd ="/usr/bin/Contents/bin/mp4box -add $TVShows2iTunes->{input}\.h264:lang=$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language} -add $TVShows2iTunes->{input}\.aac:lang=".$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language}." $subtitleSentence -keepall $device -new -fps $TVShows2iTunes->{Streams}->{MEDIA}->{Video}->{Frate} $outputfilename";				
					$m4v_cmd ="/usr/bin/Contents/bin/mp4box -add $TVShows2iTunes->{input}\.h264:lang=$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language} -add $TVShows2iTunes->{input}\.aac:lang=".$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language}." $subtitleSentence -keepall $device -new -fps $TVShows2iTunes->{Streams}->{MEDIA}->{Video}->{Frame_rate} $outputfilename";				

				}else{
					#$m4v_cmd ="/usr/bin/Contents/bin/mp4box -add $TVShows2iTunes->{input}\.h264:lang=$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language} -add $TVShows2iTunes->{input}\.ac3:lang=$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language} $subtitleSentence -add $TVShows2iTunes->{input}\.aac:lang=".$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language}." -disable 2 -group-add trackId=2:trackId=$NumeberofId -keepall $device -new -fps $TVShows2iTunes->{Streams}->{MEDIA}->{Video}->{Frate} $outputfilename";				
					$m4v_cmd ="/usr/bin/Contents/bin/mp4box -add $TVShows2iTunes->{input}\.h264:lang=$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language} -add $TVShows2iTunes->{input}\.ac3:lang=$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language} $subtitleSentence -add $TVShows2iTunes->{input}\.aac:lang=".$TVShows2iTunes->{Streams}->{MEDIA}->{Audio}->{Language}." -disable 2 -group-add trackId=2:trackId=$NumeberofId -keepall $device -new -fps $TVShows2iTunes->{Streams}->{MEDIA}->{Video}->{Frame_rate} $outputfilename";				
				}
			}
				print "$Video_cmd\n$audio_cmd\n$audio_cmd_convert\n$m4v_cmd\n";
				print "LOG :: Extracting H.264 file\n";
				system($Video_cmd);#. " &>/dev/null");
				print "LOG :: Extracting Audio file\n";
				system($audio_cmd . " &>/dev/null");
				print "LOG :: Extracting Audio ACC file\n";
				system($audio_cmd_convert);# . "&>/dev/null");
				print "LOG :: Creation of m4v file for $TVShows2iTunes->{transcode}\n";
				print "$m4v_cmd\n";
				system($m4v_cmd );# . " & /dev/null");
				system("rm -rf $ac3file");
				system("rm -rf $h264file");
				system("rm -rf $aacfile");
				system("rm -rf $avidumped");
				
				Contents::Main::IMDB::MetaData($TVShows2iTunes) if(!defined($TVShows2iTunes->{LOCAL}));
		
		}else{
			print STDERR "ERROR :: At this moment only mkv files can be transcoded (".$TVShows2iTunes->{ShortName}.")\n";
			return();
		}
	}
}


sub getStreams{
	my $TVShow2iTunes->{input}=shift;
	$TVShow2iTunes->{input}=quotemeta($TVShow2iTunes->{input});
	my $log_file="/tmp/.$$\.log" . ".log";
	my $mediainfo_cmd="/usr/bin/Contents/bin/mediainfo $TVShow2iTunes->{input} --LogFile=$log_file --Output=XML 0 1 2";
	system($mediainfo_cmd ." &>/dev/null");
	my $data = XMLin($log_file);
	foreach my $tracks (@{$data->{File}->{track}}){
		foreach my $content (keys %{$tracks}){
			if($content eq "Bit_rate"){
				$tracks->{$content} =~ s/ Kbps//g;
				$tracks->{$content} =~ s/ //g;
			}
			if($content eq "Channel_s_"){
				$tracks->{$content} =~ s/ channels//g;
			}
			if($content eq "Sampling_rate"){
				$tracks->{$content} =~ s/\.0 KHz//g;	
			}
			if($content eq "Frame_rate"){
				$tracks->{$content} =~ s/ fps//g;	
			}
			$TVShow2iTunes->{MEDIA}->{$tracks->{type}}->{$content}=$tracks->{$content}++;
		} 
	}
	
	unlink($log_file);
	return($TVShow2iTunes);
}
# 	
# 	my $Sampling_rate;
# 	my $audio;	
# 	my $videoS;	
# 	my $type;
# 	my $id;
# 	my $Bdepth;
# 	my $language;
# 	my $Codec_ID;
# 	my $Channel;
# 	my $Format;
# 	open(XML,$log_file) || die "$! ($log_file)";
# 	while(my $line=<XML>){
# 		chomp($line);
# 		if($line =~ /^<\/track>/){
# 			if($type and $id and $Bdepth and $Codec_ID and $Sampling_rate and $Channel and $Format){
# 				#print "//\nType $type\nID $id\nBdepth $Bdepth\nLangage $language\nCodec_ID $Codec_ID\nSampling_rate $Sampling_rate\nChannel $Channel\nFormat Info $Format//\n";
# 				$audio->{type}=$type;
# 				$audio->{Bdepth}=$Bdepth;
# 				$audio->{Codec_ID}=$Codec_ID;
# 				$audio->{language}=$language|| "English";
# 				$audio->{Channel}=$Channel;
# 				$audio->{id}=$id;
# 				$audio->{Sampling_rate}=$Sampling_rate;
# 				$audio->{Format}=$Format;
# 			}
# 			next;
# 		}
# 		elsif($line =~ /^<track type="Audio"/){
# 			$type="Audio";
# 		}
# 		elsif($line =~ /<ID>(\d+)<\/ID>/ ){
# 			$id=$1;
# 		}
# 		elsif($line =~ /<Format_Info>(.+)<\/Format_Info>/){
# 			$Format=$1;
# 		}
# 		elsif($line =~ /<Bit_depth>(\d+) bits<\/Bit_depth>/ or $line =~ /<Bit_rate>(d+) Kbps<\/Bit_rate>/){
# 			$Bdepth=$1;
# 		}elsif($line =~ /<Language>(\w+)<\/Language>/ ){
# 			$language=$1;
# 		}elsif($line =~ /<Codec_ID>(.+)<\/Codec_ID>/){
# 			$Codec_ID=$1;
# 		}elsif($line =~ /<Sampling_rate>(\d+)\.0 KHz<\/Sampling_rate>/){
# 			$Sampling_rate=$1;
# 		}elsif($line =~ /<Channel_s_>(\d+) channels<\/Channel_s_>/){
# 			$Channel=$1;
# 		}elsif($line =~ /<track type="Video">/ ){
# 			next;
# 		}
# 	}
# 	close XML;
# 	my $type;
# 	my $id;
# 	my $FProfile;
# 	my $Frate;
# 	my $format;
# 	my $codec_id;
# 	my $bitrate;
# 	open(XML,$log_file) || die "$!";
# 	while(my $line=<XML>){
# 		chomp($line);
# 		if($line =~ /^<\/track>/){
# 			if($type and $id and $Frate and $format and $bitrate){
# 				$videoS->{type}=$type;
# 				$videoS->{FProfile}=$FProfile;
# 				$videoS->{Frate}=$Frate;
# 				$videoS->{id}=$id;
# 				$videoS->{format}=$format;
# 				$videoS->{codec_id}=$codec_id;
# 				$videoS->{bitrate}=$bitrate;
# 				return($videoS,$audio);
# 			}
# 			next;
# 		}
# 		elsif($line =~ /^<track type="Video"/){
# 			$type="Video";
# 		}
# 		elsif($line =~ /^<Format>(\w+)<\/Format>/){
# 			$format=$1;
# 		}
# 		elsif($line =~ /<ID<Codec_ID>(\w+)<\/Codec_ID>/ ){
# 			$codec_id=$1;
# 		}
# 		elsif($line =~ /<Bit_rate>(\d+) Kbps<\/Bit_rate>/){
# 			$bitrate=$1;
# 			print ">>>>>$bitrate\n";
# 		}
# 		elsif($line =~ /<ID>(\d+)<\/ID>/ ){
# 			$id=$1;
# 		}elsif($line =~ /<Format_profile>(.+)<\/Format_profile>/ ){
# 			$FProfile=$1;
# 		}elsif($line =~ /<Frame_rate>(.+) fps<\/Frame_rate>/ ){
# 			$Frate=$1;
# 		}elsif($line =~ /<track type="Audio">/ ){
# 			next;
# 		}
# 	}
# 	close XML;
# 	#unlink($log_file);	
# }

1;
=head1 NAME

 TVShows2iTunes->{transcode}

=head1 SYNOPSIS

Description for  TVShows2iTunes->{transcode}

