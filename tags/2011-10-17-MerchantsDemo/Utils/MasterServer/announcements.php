<?
include("serverlib.php");
global $GAME_VERSION;

$Lang = $_REQUEST["lang"];
$Rev = $_REQUEST["rev"];

//First see if they are up to date
if($Rev != $GAME_VERSION)
{
	switch($Lang)
	{
		/*case 'ger':
			echo "";
			break;*/
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
	switch($Lang)
	{
		/*case 'ger':
			echo "";
			break;*/
		default:
			echo "Welcome to the Knights and Merchants Remake online!||Weekly matches are currently run every Saturday at 9pm Central European Time. Please join us if you can!|Thank you for your support!";
	}
}
?>
