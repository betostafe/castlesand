<?php
include("serverlib.php");
global $MAIN_VERSION;

$Lang = $_REQUEST["lang"];
$Rev = $_REQUEST["rev"];

if($Rev == "r2722")
{
  die("Thank you for helping me test :)");
}

//First see if they are up to date
if($Rev != $MAIN_VERSION)
{
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|";
	switch($Lang)
	{
		case 'spa':
			echo "�La version del kam Remake est� desactualizada! Est�s ejecutando ".$Rev." pero la versi�n m�s reciente es ".$MAIN_VERSION.".||Por favor bajate la actualizacion en: www.kamremake.com";
			//No puedes jugar en multijugador hasta que no actualices.
			break;
		case 'ita':
			echo "La tua versione di \"KaM Remake\" non � aggiornata! Stai utilizzando la versione ".$Rev.", mentre la pi� recente � ".$MAIN_VERSION.".||Puoi scaricare l'aggiornamento dal sito: www.kamremake.com.";
			//Non potrai giocare online prima di aver aggiornato il programma.
			break;
		case 'ptb':
			echo "Sua vers�o do KaM Remake est� desatualizada! Voc� est� executando ".$Rev." mas a vers�o mais recente � ".$MAIN_VERSION.".|| Por favor, baixe a atualiza��o em: www.kamremake.com";
			//Voc� n�o pode jogar online at� que atualize seu jogo.
			break;
		case 'hun':
			echo "A KaM Remake verzi�d t�l r�gi! Te a ".$Rev." verzi�t futtatod, mik�zben a ".$MAIN_VERSION." verzi� a leg�jabb.||K�rlek t�ltsd le a j�t�k friss�t�s�t a hivatalos oldalon: www.kamremake.com";
			//Nem j�tszhatsz interneten, am�g nem friss�ted a j�t�kodat.
			break;
		case 'rus':
			echo "���� ������ ���� ��������! �� ����������� ������ ".$Rev." ����� ��� ��������� ��������� ������ - ".$MAIN_VERSION.".||���������� �������� �� � �����: www.kamremake.com";
			//�� �� ������ ������ ������ ���� �� �������� ���� ������.
			break;
		case 'cze':
			echo "M�te zastaralou verzi KaM Remake! Pou��v�te verzi ".$Rev.", ale nejnov�j�� verze je ".$MAIN_VERSION.".||Pros�m, st�hn�te si aktualizaci na: www.kamremake.com";
			//Nem��ete hr�t online dokud neaktualizujete.
			break;
		case 'fre':
			echo "Votre version de KaM Remake n'est pas mise � jour ! Vous avez la version ".$Rev." mais la version la plus r�cente est la ".$MAIN_VERSION.".||Veuillez t�l�charger la mise � jour sur: www.kamremake.com";
			//Vous ne pouvez pas jouer en ligne tant que vous n'avez pas mis � jour votre version.
			break;
		case 'pol':
			echo "Twoja wersja KaM Remake jest nieaktualna! U�ywasz ".$Rev." ale najnowsz� jest ".$MAIN_VERSION.".||Prosz� pobra� aktualizacj� ze strony: www.kamremake.com";
			//Nie mo�esz gra� online zanim nie zaktualizujesz swojej wersji gry.
			break;
		case 'dut':
			echo "Uw KaM Remake versie is niet de nieuwste. U draait ".$Rev." maar de meest recente versie is ".$MAIN_VERSION.".||U kunt de nieuwste versie downloaden van: www.kamremake.com";
			//U kunt niet online spelen totdat u de nieuwste versie heeft ge�nstalleerd.
			break;
		case 'swe':
			echo "Du har inte den senaste versionen av KaM Remake! Du k�r ".$Rev.", medan den senaste versionen �r ".$MAIN_VERSION.".||Ladda ner uppdateringen h�r: www.kamremake.com";
			//Du kan inte spela online f�rr�n du har uppdaterat.
			break;
		case 'ger':
			echo "Deine Version des Remakes ist veraltet! Du hast ".$Rev.", die neuste ist ".$MAIN_VERSION.".||Bitte lade das neuste Update von www.kamremake.com runter.";
			//Solange du nicht die aktuelle Version hast, kannst du nicht online spielen.
			break;
		default:
			echo "Your KaM Remake version is out of date! You are running ".$Rev." but the most recent version is ".$MAIN_VERSION.".||Please download the update at: www.kamremake.com";
			//You cannot play online until you have updated.
	}
	echo "||~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!";
}
else
{
	echo "Happy New Year! :-)";
	//echo "A KaM Remake Christmas tournament is being organised!||Visit the forum to register: tinyurl.com/KAMCOMP";
	//echo "Welcome to the new version!||Have fun, report problems and spread the word :-)";
	//echo "Use our webchat to organise your games and stay in contact: www.kamremake.com/chat||Server admins: Don't forget to update your servers to r2460 if you haven't already.||Have fun :)";
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
