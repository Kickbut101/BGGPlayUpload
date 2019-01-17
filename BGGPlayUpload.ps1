# Program that will allow a user to upload gameplays that were exported from BGG website (into xml file)
# You will enter in your username and password and the script will login to the website as you and start uploading files with POSTs
# Version 1.0
# Andrew Lund




# Import xml file from the plays you want uploaded. This may change to be a user input going forward. But for now it's static
# your xml file MUST be from bgg, and it must still contain the;
# "<plays username="abcdefg" userid="12345678" total="581" page="001" termsofuse="https://boardgamegeek.com/xmlapi/termsofuse">"
# line on top
# AND the trailing "</plays>" on thh bottom
#
# The XML file MUST be more than 1 entry, and also, if the play has 1 player that player may not correctly get input, get over it, this is a work in progress.


[xml]$xmlOfPlays = (Get-Content "directlypointtoyourxmlfilehere")
# Example: [xml]$xmlOfPlays = (Get-Content "c:\made\up\directory\test.xml")



#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Function to login to account and capture cookie
# Returns cookie file

Function loginAndMakeCookie
{
# Clean up variables used, in case this script was used multiple times
Clear-Variable bggRequest,loginForm,BGG -erroraction 'silentlycontinue'

$bggRequest = Invoke-WebRequest -uri "https://www.boardgamegeek.com/login" -SessionVariable BGG
$loginForm = $bggRequest.forms[2]
$loginForm.Fields["username"] = Read-Host -Prompt "Enter Username that you want to log plays to"
$loginForm.Fields["password"]= Read-Host -Prompt "Enter Password for said account"
$r = Invoke-WebRequest -uri ("https://www.boardgamegeek.com"+$loginForm.Action) -WebSession $BGG -Method Post -Body $loginForm.Fields

return($BGG)
}






# Function to create object for each of the players per play
# Inputs: [xml]$xmlOfPlays and [Int]$arrayNumber - Both are required
# Returns object with players $playersconverted
# To call it in this particular program you need to call $playersconverted.player

Function collectPlayers
{

# Clean variables used
#Clear-Variable xmlOfPlays,arrayNumber,players,playersconverted -erroraction 'silentlycontinue'

#[Parameter(Mandatory=$true,Position=0, ParameterSetName='XML Object that contains all plays - standardized from BGG export')][xml]$xmlOfPlays,
#[Parameter(Mandatory=$true,Position=1, ParameterSetName='Current play number in array')][Int]$arrayNumber

Param([xml]$xmlOfPlays,[Int]$arrayNumber)

# Set players object that will be concatenated (however you spell that word).

$players='{"player":['

# Start for loop to add each person from xml to player object

For ($i=0;$i -lt (@($xmlOfPlays.plays.play[$arrayNumber].players.player).count);$i++)
    {


        # Set variables per user to set to the player variable, read from the xml
        
        #$usname = $xmlOfPlays.plays.play[$arrayNumber].players.player[$i].username
        #$uID = $xmlOfPlays.plays.play[$arrayNumber].players.player[$i].userid
        #$uname = $xmlOfPlays.plays.play[$arrayNumber].players.player[$i].name
        #$ustartposition = $xmlOfPlays.plays.play[$arrayNumber].players.player[$i].startposition
        #$ucolor = $xmlOfPlays.plays.play[$arrayNumber].players.player[$i].color
        #$uscore = $xmlOfPlays.plays.play[$arrayNumber].players.player[$i].score
        #$unew = $xmlOfPlays.plays.play[$arrayNumber].players.player[$i].new
        #$urating = $xmlOfPlays.plays.play[$arrayNumber].players.player[$i].rating
        #$uwin = $xmlOfPlays.plays.play[$arrayNumber].players.player[$i].win


        # Add current bracket/line for the current player into the players object. This isn't pretty I know, the above code was what
        # I had before and it was a bit easier to read

        $players +='{"username":"'+$xmlOfPlays.plays.play[$arrayNumber].players.player[$i].username+
                    '","userid":"'+$xmlOfPlays.plays.play[$arrayNumber].players.player[$i].userid+
                    '","name":"'+$xmlOfPlays.plays.play[$arrayNumber].players.player[$i].name+
                    '","position":"'+$xmlOfPlays.plays.play[$arrayNumber].players.player[$i].startposition+
                    '","color":"'+$xmlOfPlays.plays.play[$arrayNumber].players.player[$i].color+
                    '","score":"'+$xmlOfPlays.plays.play[$arrayNumber].players.player[$i].score+
                    '","new":"'+$xmlOfPlays.plays.play[$arrayNumber].players.player[$i].new+
                    '","rating":"'+$xmlOfPlays.plays.play[$arrayNumber].players.player[$i].rating+
                    '","win":"'+$xmlOfPlays.plays.play[$arrayNumber].players.player[$i].win+'"},'


    }

# so, in order to make the json formatting happy you cannot have a trailing , on last player entry. Edit string by removing trailing character

$players = $players.Substring(0,$players.length-1)

# Close the players string with closing brackets

$players += ']}'


# Let powershell formulate the data so taht it can be cleanly formatted again as json later. Yeah I know, it's mess.

$playersconverted = convertfrom-json -InputObject $players
return($playersConverted)
}




# Function to create the correct body hashtable with data required to send and post to BGG
# Inputs: [xml]$xmlOfPlays and [Int]$arrayNumber and $playersconverted
# Returns formulated $body

Function createBody

{

# I Tried...

#[Parameter(Mandatory=$true,Position=0, ParameterSetName='XML Object that contains all plays - standardized from BGG export')][xml]$xmlOfPlays
#[Parameter(Mandatory=$true,Position=1, ParameterSetName='Current play number in array')][Int]$arrayNumber
#[Parameter(Mandatory=$true,Position=2, ParameterSetName='Players object (Playersconverted object)')]$playrs

Param([xml]$xmlOfPlays,[Int]$arrayNumber,$playrs)


# Form the body hash table, it also contains an embedded hash table (the playersConverted variable)


    $body = @{
                currentUser="true"
                action="save";
                ajax ="1";
                objecttype="thing";
                objectid=$xmlOfPlays.plays.play[$arrayNumber].item.objectid;
                players= $playersConverted.player;
                nowinstats=$xmlOfPlays.plays.play[$arrayNumber].nowinstats;
                incomplete=$xmlOfPlays.plays.play[$arrayNumber].incomplete;
                length=$xmlOfPlays.plays.play[$arrayNumber].length;
                comments=$xmlOfPlays.plays.play[$arrayNumber].comments;
                playdate=$xmlOfPlays.plays.play[$arrayNumber].date;
                location=$xmlOfPlays.plays.play[$arrayNumber].location;
                quantity=$xmlOfPlays.plays.play[$arrayNumber].quantity;
                numplayers=$playersConverted.player.count;
            }


# Formulate the body variable into correct format, YES I KNOW THIS IS MESSY

$jsonBody = Convertto-json $body -depth 100


return($jsonBody)
}

# Get dat cookie

$cookie = loginAndMakeCookie


# Looping through each play after grabbing xml

For ($arrayNumber=0;$arrayNumber -lt (@($xmlOfPlays.plays.play).count);$arrayNumber++)

    {
        $playersConverted = collectPlayers $xmlOfPlays $arrayNumber
        $finalBody = createBody $xmlOfPlays $arrayNumber $playersConverted


        # This is the actual POST method to the BGG website that posts the play.

        $p = Invoke-WebRequest -uri "http://www.boardgamegeek.com/geekplay.php" -WebSession $cookie -Method Post -Body $finalBody -ContentType "application/json"

        # Clean those variables after a run
        Clear-Variable players,playersconverted,finalBody -erroraction 'silentlycontinue'

        Write-Host "Uploading play number ", ($arrayNumber + 1)
        if ($p.StatusCode -eq 200) {write-host "Play number ",($arrayNumber + 1)," uploaded successfully"}
    }
