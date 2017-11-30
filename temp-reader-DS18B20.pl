#!/usr/bin/perl

# ABSTRACT: Read temperature from USB-connected DS18B20 temperature sensor

# The sensor can be acquired here:
# https://www.aliexpress.com/item/USB-waterproof-temperature-sensor-high-precision-temperature-acquisition-free-driver-Support-Linux-system-secondary-development/32706718411.html

use strict;
use warnings;

my $max_count = shift;
my $dev = get_device();
die("No device found\n") unless $dev;
die("Unable to read from device $dev\n") unless -r $dev;

open(my $fh, '<:raw', $dev) or die "Can't open $dev: $!";
my $count = 1;
while ( read( $fh, my $bytes, 40 ) ) {
    last if length($bytes) != 40;
    print get_temp($bytes), "\n";
    last if defined $max_count and $count >= $max_count;
    $count++;
}
close($fh);

exit;

sub get_device {
    my $devnode = qx{ cat \$(find /sys/devices/ -type f | grep -P '13A5:4321.+/hidraw/.+dev\$') };
    chomp $devnode;
    return unless length $devnode;
    my ($major, $minor) = split /:/, $devnode;
    return unless length $major;
    return unless length $minor;
    my @ls_output = ( grep { /$major, $minor/ } map { chomp; $_ } qx{ ls -l /dev/hidraw* } );
    return unless scalar @ls_output;
    return unless length $ls_output[0];
    my @words = split /\s/, $ls_output[0];
    my $dev = pop @words;
    return unless length $dev;
    return unless -e $dev;
    return $dev;
}

sub get_temp {
    my ($bytes) = @_;
    my @bytes = unpack('C*', $bytes);
    my $v = $bytes[2] * 256 + $bytes[3];
    return '' if $v == 0x7FFF;
    return '' if $v == 850;
    my $temp = $v / 10;
    return sprintf("%.1f", $temp);
}
