# Program that will allow a user to upload gameplays that were exported from BGG website (into xml file)
# You will enter in your username and password and the script will login to the website as you and start uploading files with POSTs
# Version 2.0
# Andrew Lund
# Last update: 1-20-19



# Import xml file from the plays you want uploaded. This may change to be a user input going forward. But for now it's static
# your xml file MUST be from bgg, and it must still contain the;
# "<plays username="abcdefg" userid="123456" total="581" page="001" termsofuse="https://boardgamegeek.com/xmlapi/termsofuse">"
# line on top
# AND the trailing "</plays>" on thh bottom
#
# The XML file MUST be more than 1 entry, and also, if the play has 1 player that player may not correctly get input, get over it, this is a work in progress.


#[xml]$xmlOfPlays = (Get-Content "C:\temp\prodtest.xml")


####################################################################################################################################################################################################
####################################################################################################################################################################################################
####################################################################################################################################################################################################
####################################################################################################################################################################################################

# Functions;





# Menu for navigation

function Show-Menu
{
     param (
           [string]$Title = 'BGG Play Upload'
     )
     cls
     Write-Host "================ $Title ================"
     
     Write-Host "1: Choose username to read plays from"
     Write-Host "2: Add filter for games to upload (Name)"
     Write-Host "3: (Optional)Manually point to xml file that has plays"
     Write-Host "4: Upload plays (Make it happen Cap'n)"
     Write-Host ""
     Write-Host ""
     Write-Host ""
     Write-Host "============================================="
     Write-Host "Current username:",$pointedUsername,"has",$numberOfTotalPlays,"plays logged."
     Write-Host "Number of plays about to upload",$numberOfFilteredPlays
     Write-Host "Pointing to xml file at",$xmlLocation
     Write-Host "============================================="
     Write-Host "Q: Press 'Q' to quit."
}


# Function to check whether a username exists and if they have plays logged.
# Input: Username in the form of a string
# Output: Number of plays logged

Function check-UsernameOnline

{
param($pointedUsername)

If ((Invoke-WebRequest https://boardgamegeek.com/xmlapi2/plays?username=$pointedUsername`&page=1).content -like "*Invalid*")
{
Write-Host "Username either doesn't have plays or doesn't exist, please check your spelling"
pause
}
[xml]$t = (Invoke-WebRequest https://boardgamegeek.com/xmlapi2/plays?username=$pointedUsername`&page=1)
$numberOfTotalPlays = $t.plays.total
return($numberOfTotalPlays)
}

# Grab plays from online and format them correctly
# Input: Username $pointedUsername
# Output: xml file form online $xmlOfPlays

function storeOnlinePlaysAsXML

{
param ($pointedUsername)
clear-variable xmlofplays -ErrorAction SilentlyContinue
[xml]$D = (Invoke-WebRequest https://boardgamegeek.com/xmlapi2/plays?username=$pointedUsername`&page=1)
$numberOfTotalPlays = $D.plays.total
if ($numberOfTotalPlays -gt 100)
    {
        For ($i=1;$i -lt [int](($numberOfTotalPlays -split '\B')[0]) + 2; $i++)
        {
        [xml]$D = (Invoke-WebRequest https://boardgamegeek.com/xmlapi2/plays?username=$pointedUsername`&page=$i)
        $xmlOfPlays += $D.plays.play
        }


    }

Elseif ($numberOfTotalPlays -gt 999)

    {
        For ($i=1;$i -lt [int](-join($numberOfTotalPlays -split '\B')[0,1]) + 2; $i++)
        {
        [xml]$D = (Invoke-WebRequest https://boardgamegeek.com/xmlapi2/plays?username=$pointedUsername`&page=$i)
        $xmlOfPlays += $D.plays.play
        }


    }

Else
    {
        [xml]$D = (Invoke-WebRequest https://boardgamegeek.com/xmlapi2/plays?username=$pointedUsername`&page=1)
        $xmlOfPlays += $D.plays.play

    }

Write-Host "If you saw an error pop up or you think it's not showing all your plays run this option again"
Return($xmlOfPlays)
}


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
Clear-Variable bggRequest,loginForm -erroraction 'silentlycontinue'
return($BGG)
}


# Function to grab file location for xml file, shamelessly copy-pasta'd from teh internet

Function Get-FileName($initialDirectory)
{   
 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
 Out-Null

 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = $initialDirectory
 $OpenFileDialog.filter = "All files (*.*)| *.*"
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
} #end function Get-FileName



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

Param($xmlOfPlays,[Int]$arrayNumber)

# Set players object that will be concatenated (however you spell that word).

$players='{"player":['

# Start for loop to add each person from xml to player object

For ($i=0;$i -lt (@($xmlOfPlays[$arrayNumber].players.player).count);$i++)
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

        $players +='{"username":"'+$xmlOfPlays[$arrayNumber].players.player[$i].username+
                    '","userid":"'+$xmlOfPlays[$arrayNumber].players.player[$i].userid+
                    '","name":"'+$xmlOfPlays[$arrayNumber].players.player[$i].name+
                    '","position":"'+$xmlOfPlays[$arrayNumber].players.player[$i].startposition+
                    '","color":"'+$xmlOfPlays[$arrayNumber].players.player[$i].color+
                    '","score":"'+$xmlOfPlays[$arrayNumber].players.player[$i].score+
                    '","new":"'+$xmlOfPlays[$arrayNumber].players.player[$i].new+
                    '","rating":"'+$xmlOfPlays[$arrayNumber].players.player[$i].rating+
                    '","win":"'+$xmlOfPlays[$arrayNumber].players.player[$i].win+'"},'


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

Param($xmlOfPlays,[Int]$arrayNumber,$playrs)


# Form the body hash table, it also contains an embedded hash table (the playersConverted variable)


    $body = @{
                currentUser="true"
                action="save";
                ajax ="1";
                objecttype="thing";
                objectid=$xmlOfPlays[$arrayNumber].item.objectid;
                players= $playersConverted.player;
                nowinstats=$xmlOfPlays[$arrayNumber].nowinstats;
                incomplete=$xmlOfPlays[$arrayNumber].incomplete;
                length=$xmlOfPlays[$arrayNumber].length;
                comments=$xmlOfPlays[$arrayNumber].comments;
                playdate=$xmlOfPlays[$arrayNumber].date;
                location=$xmlOfPlays[$arrayNumber].location;
                quantity=$xmlOfPlays[$arrayNumber].quantity;
                numplayers=$playersConverted.player.count;
            }


# Formulate the body variable into correct format, YES I KNOW THIS IS MESSY

$jsonBody = Convertto-json $body -depth 100


return($jsonBody)
}


####################################################################################################################################################################################################
####################################################################################################################################################################################################
####################################################################################################################################################################################################
####################################################################################################################################################################################################
####################################################################################################################################################################################################

# Main()



Clear-Variable pointedUsername,xmlofbody,numberOfTotalPlays,numberOfFilteredPlays,xmlLocation,xmlofplays -ErrorAction 'silentlyContinue'

do
{

     Show-Menu
     $input = Read-Host "Please make a selection"
     switch ($input.toupper())
     {
           '1' # "1: Choose username to read plays from"
           {
           Clear-Variable pointedUsername,numberOfTotalPlays -ErrorAction 'silentlyContinue'
                cls
                Write-Host "What is the username you'd like to grab the plays from?"

                # Ask user for the username to read plays from, use case would be that this is the username of your friend who logs all the plays

                $pointedUsername = Read-Host
                $numberOfTotalPlays = check-UsernameOnline -pointedUsername $pointedUsername
                $xmlOfPlays = storeOnlinePlaysAsXML -pointedUsername $pointedUsername
           } 
           
           
           '2' # "2: Add filter for games to upload (Name)"
           {
                cls
                Write-Host "Please choose the name in which to filter the games by (Probably your name)"

                # Ask user to pick a name to further filter the plays, in the use case of your buddy recording your plays, and you 
                # wanting to upload your plays that you were part of

                $name = ($xmlOfPlays.players.player.name |Sort-Object | Select-Object -Unique | Out-GridView -passthru)
                $xmlOfPlays = $xmlOfPlays.where({ $_.players.player.name -like $name})
                $numberOfFilteredPlays = $xmlOfPlays.count


           } 


           '3' # "3: (Optional)Manually point to xml file that has plays"
           {
                Clear-Variable pointedUsername,numberOfTotalPlays,numberOfFilteredPlays -ErrorAction 'silentlyContinue'
                cls

                Write-Host "Please point to the xml file with the plays you'd like to upload"
                Pause

                # Ask user for location of xml file to locally read plays from

                $xmlLocation = Get-FileName -initialDirectory "$env:userprofile\downloads"

                # Load up the xml into variable $Temp

                [xml]$Temp = (Get-Content "$xmlLocation")

                # Fill the variables needed

                $xmlOfPlays = $temp.plays.play
                $pointedUsername = $temp.plays.username
                $numberOfTotalPlays = $temp.plays.play.count
           } 
           
           '4' # 4: Upload plays (Make it happen Cap'n)
           {
                cls

                # Grab cookie for use to post plays

                $cookie = loginAndMakeCookie

                # Start loop to post each play

                For ($arrayNumber=0;$arrayNumber -lt (@($xmlOfPlays).count);$arrayNumber++)

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

                        Clear-Variable pointedUsername,xmlofbody,numberOfTotalPlays,numberOfFilteredPlays,xmlLocation -ErrorAction 'silentlyContinue'
           } 
           
           'q' 
           
           {
                return
           }
     }
     pause
}
until ($input -eq 'q')
