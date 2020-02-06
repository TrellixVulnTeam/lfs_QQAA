package Lfs::PkgList;
use strict;
use warnings;

use autodie qw(:all);
use File::Path qw(mkpath rmtree);
use Lfs::Pkg;

my $list="doc/wget-list.txt";
$|++;

our(%self,$self,@pkg);

sub new
{
  my ($class) = map { ref || $_ } shift;
  local($self,%self,@pkg);
  $self=\%self;
  bless($self,$class);
  *self=$self;
  $self{pkg}={};
  $self{src}=[ qw(doc/wget-list.txt) ];
  $self{pat}=[];
  $self{cfg}{jobs}=8;
  $self{jobs}={};

  local (@ARGV);
  @ARGV= @{$self{src}};
  while(<>) {
    chomp;
    if(/\.patch$/){
      push(@{$self{pat}},$_);
    } elsif (/[.]html[.]tar[.][bxg]z2?$/) {
      push(@{$self{pat}},$_);
    } else {
      my $pkg=new Lfs::Pkg( $_ );
      $self{pkg}{$pkg->{pkg}}=$pkg;
    };
  };
  return $self;
}
sub cleanup {
  my $self=shift;
  my ($pid,$err);
  $pid=wait;
  $err=$?;
  return 0 if $pid<0;
  our(%pkg);
  local *pkg=delete $self{jobs}{$pid};
  print "$pkg{pkg} done $err\n";
  return 1;
};
sub limit_jobs {
  local($self,%self)=shift;
  *self=$self;
  our(%jobs);
  local(%jobs);
  *jobs=$self{jobs};

  while(1) {
    my $jobs=scalar(keys %jobs);
    my $limit=$self{cfg}{jobs};
    last if $jobs <= $limit;
    $self->cleanup();
  };
};
sub pkg_list {
  local($self,%self)=shift;
  *self=$self;
  return [ values %{$self{pkg}} ];
};
sub get {
  local($self,%self)=shift;
  *self=$self;
  return $self{pkg}{+shift};
};
sub untar_all {
  local($self,%self)=shift;
  *self=$self;

  our(%pkg);

  for(values %{$self->{pkg}}) {
    use Data::Dumper;
    my $pkg=$_->{pkg};
    if(-d "src/$pkg") {
      warn "pkg dir $pkg exists.  skipping.\n";
      next;
    };
    $self->limit_jobs;
    print "untarring: ", $_->{pkg}, "\n";
    my $pid;

    if($self{cfg}{jobs}>1){
      $pid=fork;
      if(!$pid) {
        if($_->untar("src/$pkg")) {
          exit(0);
        } else {
          die "untar failed";
        };
      }

      $_->{pid}=$pid;
      $self{jobs}{$pid}=$_;
    } else {
      $_->untar("src/$pkg");
    };
  };
  while( scalar(keys %{$self{jobs}}) ) {
    cleanup();
  };
};

1;
