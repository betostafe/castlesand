﻿<?php

global $DATA_FILE, $DISALLOWED_CHARS, $GAME_VERSION, $MAX_TTL, $DO_STATS;
$DO_STATS = true;
$GAME_VERSION = 'r2411';
$MAX_TTL = 600; //10 minutes
$DATA_FILE = "servers.txt";
$DISALLOWED_CHARS  = array("|", ",","\n","\r");

if ($DO_STATS) include("statistics.php");

function CheckVersion($aRev)
{
	global $GAME_VERSION;
	return ($aRev == $GAME_VERSION);
}

function plural($count, $singular, $plural = 's') {
    if ($plural == 's') {
        $plural = $singular . $plural;
    }
    return ($count == 1 ? $singular : $plural);
}


function GetStats($Format)
{
	global $DATA_FILE;
	$ServerCount = 0;
	$TotalPlayerCount = 0;
	if(!file_exists($DATA_FILE))
		return "";
	$Lines = file($DATA_FILE);
	foreach($Lines as $Line)
	{
		//Data does not yet use quotes or backslashes, but it might in future
		$Line = trim(stripslashes_if_gpc_magic_quotes($Line));
		list($Name,$IP,$Port,$PlayerCount,$Expiry) = explode("|",$Line);
		if(time() < $Expiry)
		{
			$ServerCount++;
			$TotalPlayerCount = $TotalPlayerCount + $PlayerCount;
		}
	}
	switch ($Format)
	{
		case "kamclub":
			return '<html><head><META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8"></head><body><div style="font-size:11px; font-family:Arial,Tahoma"><b>Кол-во серверов:</b> '.$ServerCount.'<BR><b>Кол-во игроков:</b> '.$TotalPlayerCount.'</font></div></body></html>';
		case "ajaxupdate":
			return '{'."\n".'"pct": "'.$TotalPlayerCount.'",'."\n".'"sct": "'.$ServerCount.'"'."\n".'}';
		case "csv":
			return $ServerCount.','.$TotalPlayerCount;
		case "refresh":
			$startscript = '<script type="text/javascript">'."\n".
			'function updnr(){setTimeout(function(){jQuery.getJSON("http://lewin.hodgman.id.au/kam_remake_master_server/serverstats.php?format=ajaxupdate",function(data){jQuery("#scount").empty().append(data.sct);jQuery("#pcount").empty().append(data.pct);updnr();});},30000);}'."\n".
			'jQuery(document).ready(function($){updnr();});'."\n".'</script><span id="ajaxplayers"></span>';
			return $startscript.'There '.plural($ServerCount,'is','are',true).' <span id="scount">'.$ServerCount.'</span> '.plural($ServerCount,'server').' running and <span id="pcount">'.$TotalPlayerCount.'</span> '.plural($TotalPlayerCount,'player').' online';
		default:
			return 'There '.plural($ServerCount,'is','are',true).' '.$ServerCount.' '.plural($ServerCount,'server').' running and '.$TotalPlayerCount.' '.plural($TotalPlayerCount,'player').' online';
	}
}

function GetServers($aFormat)
{
	global $DATA_FILE;
	include("flag.php");
	$Result = "";
	if(!file_exists($DATA_FILE))
		return "";
	$Lines = file($DATA_FILE);
	foreach($Lines as $Line)
	{
		//Data does not yet use quotes or backslashes, but it might in future
		$Line = trim(stripslashes_if_gpc_magic_quotes($Line));
		list($Name,$IP,$Port,$PlayerCount,$Expiry) = explode("|",$Line);
		if(time() < $Expiry)
		{
			switch($aFormat)
			{
				case "table":
					$Country = IPToCountry($IP);
					$Result .= "<TR><TD><IMG src=\"http://lewin.hodgman.id.au/kam_remake_master_server/flags/".strtolower($Country).".gif\" alt=\"".GetCountryName($Country)."\">&nbsp;$Name</TD><TD>$IP: $Port</TD><TD>$PlayerCount</TD></TR>\n";
					break;
				default:
					$Result .= "$Name,$IP,$Port\n";
			}
		}
	}
	return $Result;
}

function AddServer($aName,$aIP,$aPort,$aPlayerCount,$aTTL)
{
	global $DATA_FILE, $DISALLOWED_CHARS, $MAX_TTL, $DO_STATS;
	//Remove characters that are not allowed (used for internal formatting)
	$aName = str_replace($DISALLOWED_CHARS,"",$aName);
	$aIP = str_replace($DISALLOWED_CHARS,"",$aIP);
	$aPort = str_replace($DISALLOWED_CHARS,"",$aPort);
	$aTTL = str_replace($DISALLOWED_CHARS,"",$aTTL);
	$aPlayerCount = str_replace($DISALLOWED_CHARS,"",$aPlayerCount);
	//Enforce max TTL, so people can not add a server that lasts a thousand years!
	$aTTL = min($aTTL,$MAX_TTL);
	$Servers = "";
	$Exists = false;
	
	if ($DO_STATS) StatsUpdate($aName,$aPlayerCount);
	
	if(file_exists($DATA_FILE))
	{
		$Lines = file($DATA_FILE);
		foreach($Lines as $Line)
		{
			//Data does not yet use quotes or backslashes, but it might in future
			$Line = trim(stripslashes_if_gpc_magic_quotes($Line));
			list($Name,$IP,$Port,$PlayerCount,$Expiry) = explode("|",$Line);
			if(time() < $Expiry)
			{
				if(($IP == $aIP) && ($Port == $aPort))
				{
					$Servers .= "$aName|$IP|$Port|$aPlayerCount|".(time()+$aTTL)."\n";
					$Exists = true;
				}
				else
				{
					$Servers .= "$Name|$IP|$Port|$PlayerCount|$Expiry\n";
				}
			}
		}
	}
	if(!$Exists)
	{
		$Servers .= "$aName|$aIP|$aPort|$aPlayerCount|".(time()+$aTTL)."\n";
	}
	$fh = fopen($DATA_FILE, 'w') or die("can't open file");
	fwrite($fh, $Servers);
	fclose($fh);
	return 'Success';
}

function stripslashes_if_gpc_magic_quotes( $string ) {
    if(get_magic_quotes_gpc()) {
        return stripslashes($string);
    } else {
        return $string;
    }
}

?>
