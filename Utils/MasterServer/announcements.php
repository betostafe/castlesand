<?php
include("serverlib.php");
global $GAME_VERSION;

$Lang = $_REQUEST["lang"];
$Rev = $_REQUEST["rev"];

//First see if they are up to date
if($Rev != $GAME_VERSION)
{
	switch($Lang)
	{
		case 'hun':
			echo "A KaM Remake verzi�d t�l r�gi! Te a ".$Rev." verzi�t futtatod, mik�zben a ".$GAME_VERSION." verzi� a leg�jabb.|Nem j�tszhatsz interneten, am�g nem friss�ted a j�t�kodat.||K�rlek t�ltsd le a j�t�k friss�t�s�t a hivatalos oldalon: www.kamremake.com";
			break;
		case 'rus':
			echo "���� ������ ���� ��������! �� ����������� ������ ".$Rev." ����� ��� ��������� ��������� ������ - ".$GAME_VERSION.".|�� �� ������ ������ ������ ���� �� �������� ���� ������.||���������� �������� �� � �����: www.kamremake.com";
			break;
		case 'cze':
			echo "M�te zastaralou verzi KaM Remake! Pou��v�te verzi ".$Rev.", ale nejnov�j�� verze je ".$GAME_VERSION.".|Nem��ete hr�t online dokud neaktualizujete.||Pros�m, st�hn�te si aktualizaci na: www.kamremake.com";
			break;
		case 'fre':
			echo "Votre version de KaM Remake n'est pas mise � jour ! Vous avez la version ".$Rev." mais la version la plus r�cente est la ".$GAME_VERSION.".|Vous ne pouvez pas jouer en ligne tant que vous n'avez pas mis � jour votre version.||Veuillez t�l�charger la mise � jour sur: www.kamremake.com";
			break;
		case 'pol':
			echo "Twoja wersja KaM Remake jest nieaktualna! U�ywasz ".$Rev." ale najnowsz� jest ".$GAME_VERSION.".|Nie mo�esz gra� online zanim nie zaktualizujesz swojej wersji gry.||Prosz� pobra� aktualizacj� ze strony: www.kamremake.com";
			break;
		case 'dut':
			echo "Uw KaM Remake versie is niet de nieuwste. U draait ".$Rev." maar de meest recente versie is ".$GAME_VERSION.".|U kunt niet online spelen totdat u de nieuwste versie heeft ge�nstalleerd.||U kunt de nieuwste versie downloaden van: www.kamremake.com";
			break;
		case 'swe':
			echo "Du har inte den senaste versionen av KaM Remake! Du k�r ".$Rev.", medan den senaste versionen �r ".$GAME_VERSION.".|Du kan inte spela online f�rr�n du har uppdaterat.||Ladda ner uppdateringen h�r: www.kamremake.com";
			break;
		case 'ger':
			echo "Deine Version des Remakes ist veraltet! Du hast ".$Rev.", die neuste ist ".$GAME_VERSION.".|Solange du nicht die aktuelle Version hast, kannst du nicht online spielen.||Bitte lade das neuste Update von www.kamremake.com runter.";
			break;
		default:
			echo "Your KaM Remake version is out of date! You are running ".$Rev." but the most recent version is ".$GAME_VERSION.".|You cannot play online until you have updated.||Please download the update at: www.kamremake.com";
	}
}
else
{
	echo "Use our webchat to organise your games and stay in contact: www.kamremake.com/chat||Server admins: Don't forget to update your servers to r2460 if you haven't already.||Have fun :)";
	//echo "TO THE OWNERS OF THE FOLLOWING SERVERS:|KaM srv from Natodia|[PL] Reborn Army KaM Server||You need to update your servers to r2460 ASAP. (download at www.kamremake.com) Due to bugs in the old server versions there are \"ghost\" players on your server which failed to disconnect properly.|If anyone knows the owners of these servers, please ask them to update. Playing on these servers is not recommended as they are more likely to crash your game.";
	//echo 'There is a new Servers page on the website! Check it out at www.kamremake.com/servers||We have also released an update to the dedicated server that fixes crashes on Linux. Please update your servers as soon as possible to the new version r2460. Thanks to everyone who helped test this server fix.';
	//echo 'WE NEED YOUR HELP!|We are having difficulties with the Linux build of the dedicated server. The servers occasionally crash which stops all games running on them. The following servers are running a new unreleased fix (r2446) which we are testing for release:| - [DE] KaM Remake Server| - Linux r2446 Server| - Jecy\'s r2446 Dedicated Server|Please help us by playing in these servers as much as possible until further notice. This will help us assess whether the crashes are fixed. Thanks! :)';
	/*switch($Lang)
	{
		case 'ger':
			echo "Willkommen bei Knights and Merchants Remake Online!||Jeden Samstag um 21Uhr CET finden Wettk�mpfe statt. Seid dabei! Danke f�r Eure Unterst�tzung!";
			break;
		default:
			echo "Welcome to the Knights and Merchants Remake online!||Weekly matches are currently run every Saturday at 9pm Central European Time. Please join us if you can!|Thank you for your support!";
	}*/
}
?>
