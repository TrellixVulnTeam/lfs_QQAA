package Lfs::Pkg;
use strict;
use warnings;
use autodie qw(:all);
use File::Path qw(mkpath rmtree);

use Data::Dumper;
our(%self,$self);
sub new {
  my ($class) = map { ref || $_ } shift;
  local(%self,$self);
  $self=\%self;
  $self{url}=$_=shift;
  die "no url!" unless defined;
  if( m{(.*)/(.*)} ) {
    $self{loc}=$1;
    $self{arc}=$2;
  };
  $_="$self{arc}";
  ($_,$self{ext})=m{(.*)([.]tar[.].*)};
  if( m{(.*)-([0-9].*)} ) {
    $self{pkg}=$1;
    $self{sep}="-";
    $self{ver}=$2;
  } elsif(m{(.*?[^0-9])([0-9].*)}) {
    $self{pkg}=$1;
    $self{sep}="";
    $self{ver}=$2;
  };
  my $tmp =sprintf("%s/%s%s%s%s", map { $self{$_} } qw(loc pkg sep ver ext ));
  my $url=$self{url};
  if($tmp ne $url ) {
    print "($tmp)\n";
    print "[$self{url}]\n";
    die Dumper($self) unless $tmp eq $url;;
  };
  bless($self,$class); 
  return $self;
}
sub untar {
  local($self,%self)=shift;
  my $src=shift;
  die unless defined $src;
  $src=~s{/*$}{};
  my $tmp="$src.$$";
  *self=$self;
  if(-d "$src") {
    warn "pkg dir exists.  skipping.\n";
    return 1;
  };
  mkpath($tmp);
  {
    my @cmd=(qw(tar), "-xf", "arc/$self{arc}", "-C", $tmp);
    print "running (@cmd)\n";
    system(@cmd);
    if($?) {
      print "tar failed!\n";
      rmpath($tmp);
      return undef;
    } else {
      rename($tmp,$src);
      return 1;
    };
  };
};
1;
