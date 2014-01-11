<?php
function EchoUpdateMessage($Lang, $Rev, $MAIN_VERSION)
{
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|";
	switch($Lang)
	{
		case 'tur':
			echo "Eski bir KaM Remake versiyonu kullan�yorsunuz! ".$Rev." versiyonunu kullan�yorsunuz fakat ".$MAIN_VERSION." versiyonu kullan�labilir durumda.||L�tfen www.kamremake.com adresinden g�ncellemeyi indiriniz.";
			break;
		case 'jpn':
			echo "Anata no KAM Remake no ba-jon wa jidaiokure desu yo!�@".$Rev." ga jikkou saremashite iru, shikashi ".$MAIN_VERSION." ba-jon wa yori saikin desu. Kono rinku (www.kamremake.com) kara appude-to ga daunro-do saremashite kudasai.";
			break;
		case 'bel':
			echo "���� ����� KaM Remake ��������! �� �������������� ".$Rev.", � ����� ������� ����� ".$MAIN_VERSION.". ||��� ����� �������� ��������� �� ������: www.kamremake.com";
			break;
		case 'nor':
			echo "Din versjon av KaM Remake er utdatert! Du kj�rer ".$Rev." men den mest nylige versjonen er ".$MAIN_VERSION.".||Vennligst last ned oppdateringen p�: www.kamremake.com";
			break;
		case 'ukr':
			echo "���� ".$Rev." ����� KaM Remake ��������! ���������� ���� ".$MAIN_VERSION." ����������� �� ����: www.kamremake.com";
			break;
		case 'rom':
			echo "Versiunea ta de KaM Remake este expirat�! Acum rulezi ".$Rev." dar cea mai recent� versiune este ".$MAIN_VERSION.".||Te rug�m s� descarci update-ul de la www.kamremake.com";
			break;
		case 'svk':
			echo "Va�a verzia KaM Remake je zastaral�! M�te spusten� verziu ".$Rev.", ale posledn� verzia je ".$MAIN_VERSION.".||Pros�m, stiahnite si aktualiz�ciu na str�nke: www.kamremake.com";
			break;
		case 'est':
			echo "Teie KaM Remake versioon on vana! Teie versioon on ".$Rev." , aga viimane versioon on ".$MAIN_VERSION.".||Palun laadige alla uuendus: www.kamremake.com";
			break;
		case 'bul':
			echo "�������� �� ������ � � ��-����� ������! ��� ���������� ".$Rev." ,�� �� ���������� ���������� ������, ����� � ".$MAIN_VERSION.".||���� ��������� ������� ��: www.kamremake.com";
			break;
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
			echo "La version de KaM Remake que vous utilisez n'est pas mise � jour !|Vous avez la version ".$Rev." alors que la version la plus r�cente est la ".$MAIN_VERSION.".||Veuillez t�l�charger la mise � jour sur www.kamremake.com.";
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
?>