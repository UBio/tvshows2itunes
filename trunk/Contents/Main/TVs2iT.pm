#
#  TVs2iT
#
#  Created by Eduardo Andrés León on 2012-03-18.
#  Copyright (c) 2012 CNIO. All rights reserved.
#

package Contents::Main::TVs2iT;
use strict;
use Contents::Main::GetSubtitles;
use Contents::Main::IMDB;
use Contents::Main::Transcode;
sub new{
	my ($class,%args)=@_;
	my $TVShow2iTunes={};
	$TVShow2iTunes->{input}=$args{input};
	$TVShow2iTunes->{transcode}=$args{transcode};
	$TVShow2iTunes->{lang}=$args{lang};
	$TVShow2iTunes->{app_name}="TVShow2iTunes";
	bless($TVShow2iTunes);
	$TVShow2iTunes->language_codes();
	return($TVShow2iTunes);
}
=head2 TVs2iT

  Example    : 
  Description: This method returns a string that is considered to be
               the 'display' identifier.
  Returntype : String
  Exceptions : none
  Caller     : web drawing code
  Status     : Stable

=cut

sub main{
	my $TVShow2iTunes=shift;
	
	if($TVShow2iTunes->{input} !~ /\.srt/ and $TVShow2iTunes->{input} !~ /\.m4v/){
		#getting the filename
		$TVShow2iTunes->{ShortName}=substr($TVShow2iTunes->{input}, rindex($TVShow2iTunes->{input},"/")+1,length($TVShow2iTunes->{input})-rindex($TVShow2iTunes->{input},"/")-1);
		print STDERR "Searching for " .$TVShow2iTunes->{ShortName}."\n";

		#getSubtitle
		Contents::Main::GetSubtitles::GetSubtitles($TVShow2iTunes);

		##Getting the metadata########
		if(${$TVShow2iTunes->{imdbs}}[0]){
			Contents::Main::IMDB->getMetaDataIMDBAPI($TVShow2iTunes);
			#getMetaDataIMDBPERL($imdb);
			#getMetaDataOpen($imdb);
			#############################
			#Converting to m4v with subtitles
			if($TVShow2iTunes->{transcode}){
				Contents::Main::Transcode::Recoding($TVShow2iTunes);
			}
		}else{
			#Converting to m4v without subtitles
			if($TVShow2iTunes->{transcode}){
				# Recoding($TVShow2iTunes->{input},$transcode,"NO");
				Contents::Main::Transcode::Recoding($TVShow2iTunes);
			}
		}
		print "LOG :: Done !\n";
		return();
	}else{
		print STDERR "ERROR :: Input file (".$TVShow2iTunes->{input}.")¿?\n";
	}
return();
}

sub language_codes{
	my $TVShow2iTunes=shift;
	$TVShow2iTunes->{CodeFile}="Contents/Main/Codes.txt";
	open(CODES,$TVShow2iTunes->{CodeFile}) || die "ERROR :: $!\n";
	while(<CODES>){
		chomp;
		my ($IdSubLanguage,$ISO639,$LanguageName,$UploadEnabled,$WebEnabled)=split(/\t/,$_);
		$TVShow2iTunes->{ISO639}->{$IdSubLanguage}=$ISO639++;
		$TVShow2iTunes->{IdSubLanguage}->{$IdSubLanguage}=$LanguageName++;
	}
	close CODES;
	return();
}
1;
=head1 NAME

 TVs2iT

=head1 SYNOPSIS

Description for  TVs2iT

