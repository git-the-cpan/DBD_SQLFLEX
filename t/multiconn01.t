#!/usr/bin/perl -w
#
#	@(#)$Id: multiconn01.t,v 54.3 1997/05/13 12:55:21 johnl Exp $ 
#
#	Test Multiple Connections for DBD::Sqlflex
#
#	Copyright (C) 1996,1997 Jonathan Leffler

use DBD::SqlflexTest;

$dbase1 = $ENV{DBD_INFORMIX_DATABASE};
$dbase1 = "stores" unless ($dbase1);
$dbase2 = $ENV{DBD_INFORMIX_DATABASE2};
$dbase2 = $dbase1 unless ($dbase2);

sub info_usertables
{
	my ($dbh) = @_;
	my ($sth);
	my ($row);

	my ($stmt) =
		"SELECT TabName FROM 'informix'.SysTables" .
		" WHERE TabID >= 100 AND TabType = 'T'" .
		" ORDER BY TabName";
	&stmt_fail() unless ($sth = $dbh->prepare($stmt));
	&stmt_ok();
	&stmt_fail() unless ($sth->execute());
	&stmt_ok();
	$n = 0;
	while ($row = $sth->fetch())
	{
		@row = @{$row};
		print "# $n: $row[0]\n";
		$n++;
	}
	&stmt_fail() unless ($sth->finish());
	&stmt_ok();
}

# Test install...
&stmt_note("# Testing: DBI->install_driver('Sqlflex')\n");
$drh = DBI->install_driver('Sqlflex');

print "# Driver Information\n";
print "#     Name:                  $drh->{Name}\n";
print "#     Version:               $drh->{Version}\n";
print "#     Product:               $drh->{ix_ProductName}\n";
print "#     Product Version:       $drh->{ix_ProductVersion}\n";
print "#     Multiple Connections:  $drh->{ix_MultipleConnections}\n";
print "# \n";

if ($drh->{ix_MultipleConnections} == 0)
{
	&stmt_note("1..1\n");
	&stmt_note("# Multiple connections are not supported\n");
	&stmt_ok(0);
	&all_ok();
}

&stmt_note("1..23\n");
&stmt_ok();

&stmt_note("# Connect to: $dbase1\n");
&stmt_fail() unless ($dbh1 = $drh->connect($dbase1));
&stmt_ok();

print "# Database Information\n";
print "#     Database Name:           $dbh1->{Name}\n";
print "#     AutoCommit:              $dbh1->{AutoCommit}\n";
print "#     Sqlflex-OnLine:         $dbh1->{ix_SqlflexOnLine}\n";
print "#     Logged Database:         $dbh1->{ix_LoggedDatabase}\n";
print "#     Mode ANSI Database:      $dbh1->{ix_ModeAnsiDatabase}\n";
print "#     AutoErrorReport:         $dbh1->{ix_AutoErrorReport}\n";
print "#     Transaction Active:      $dbh1->{ix_InTransaction}\n";
print "#\n";

&info_usertables($dbh1);

&stmt_note("# Connect to: $dbase2\n");
&stmt_fail() unless ($dbh2 = $drh->connect($dbase2));
&stmt_ok();

print "# Database Information\n";
print "#     Database Name:           $dbh2->{Name}\n";
print "#     AutoCommit:              $dbh2->{AutoCommit}\n";
print "#     Sqlflex-OnLine:         $dbh2->{ix_SqlflexOnLine}\n";
print "#     Logged Database:         $dbh2->{ix_LoggedDatabase}\n";
print "#     Mode ANSI Database:      $dbh2->{ix_ModeAnsiDatabase}\n";
print "#     AutoErrorReport:         $dbh2->{ix_AutoErrorReport}\n";
print "#     Transaction Active:      $dbh2->{ix_InTransaction}\n";
print "#\n";

&info_usertables($dbh2);

# Demonstrate that previous database is still accessible...
&info_usertables($dbh1);

$stmt1 =
	"SELECT TabName FROM 'informix'.SysTables" .
	" WHERE TabID >= 100 AND TabType = 'T'" .
	" ORDER BY TabName";

$stmt2 =
	"SELECT ColName, ColType FROM 'informix'.SysColumns" .
	" WHERE TabID = 1 ORDER BY ColName";

&stmt_fail() unless ($st1 = $dbh1->prepare($stmt1));
&stmt_ok();
&stmt_fail() unless ($st2 = $dbh2->prepare($stmt2));
&stmt_ok();

&stmt_fail() unless ($st1->execute);
&stmt_ok();
&stmt_fail() unless ($st2->execute);
&stmt_ok();

LOOP: while (1)
{
	# Yes, these are intentionally different!
	last LOOP unless (@row1 = $st1->fetchrow);
	last LOOP unless ($row2 = $st2->fetch);
	print "# 1: $row1[0]\n";
	print "# 2: ${$row2}[0]\n";
	print "# 2: ${$row2}[1]\n";
}

while (@row1 = $st1->fetchrow)
{
	print "# 1: $row1[0]\n";
}
&stmt_fail() unless ($st1->finish);
&stmt_ok();

while ($row2 = $st2->fetch)
{
	print "# 2: ${$row2}[0]\n";
	print "# 2: ${$row2}[1]\n";
}
&stmt_fail() unless ($st2->finish);
&stmt_ok();

&stmt_note("# Testing: \$dbh1->disconnect()\n");
&stmt_fail() unless ($dbh1->disconnect);
&stmt_ok();

&info_usertables($dbh2);

&stmt_note("# Testing: \$dbh2->disconnect()\n");
&stmt_fail() unless ($dbh2->disconnect);
&stmt_ok();

&all_ok();
