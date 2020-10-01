function Get-PublicIpAddress
{
    $url = "http://checkip.dyndns.com"   
    $webclient = New-Object System.Net.WebClient  
    $response = $webclient.DownloadString($url).Trim()
    $ip = (Select-String -InputObject $response -Pattern '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').Matches.Value
    $ip
}

function Get-IpAddresses
{
    Param(
    
        [parameter(Mandatory=$true)]
        [string]$cidr,

        [parameter(Mandatory=$true)]
        [string]$network

    )

    $subnet = $network.split('.')

    $size= ''
    if ($cidr -eq '22'){$octet2 = '4'; $octet3 = '256'}
    elseif ($cidr -eq '23'){$octet2 = '2'; $octet3 = '256'}
    elseif ($cidr -eq '24'){$octet3 = '256'}
    elseif ($cidr -eq '25'){$octet3 = '128'}
    elseif ($cidr -eq '26'){$octet3 = '64'}
    elseif ($cidr -eq '27'){$octet3 = '32'}
    elseif ($cidr -eq '28'){$octet3 = '16'}
    elseif ($cidr -eq '29'){$octet3 = '8'}
    elseif ($cidr -eq '30'){$octet3 = '4'}
    elseif ($cidr -eq '31'){$octet3 = '2'}
    elseif ($cidr -eq '32'){$octet3 = '1'}
    else {$size -eq $null}

    if ($cidr -le 23)
    {
        if ($size -ne $null)
        {
            for ($i = [int]$subnet[2]; $i -le [int]$octet2; $i++)
            {
                for ($ii = [int]$subnet[3]; $ii -lt [int]$octet3; $ii++)
                {
                    $subnet[0] + '.' + $subnet[1] + '.' + $i + '.' + $ii
                }
            }
        }
    }
    else
    {
        if ($size -ne $null)
        {
            for ($i = [int]$subnet[3]; $i -lt [int]$octet3; $i++)
            {
                $subnet[0] + '.' + $subnet[1] + '.' + $subnet[2] + '.' + $i
            }
        }
    }
}

function Send-Email
{
    Param(

        #Sender email address
        [parameter(Mandatory=$true)]
        [string]$MailFrom,

        #Recipient email address
        [parameter(Mandatory=$true)]
        [string]$MailTo,

        #Sender SMTP Username
        [parameter(Mandatory=$true)]
        [string]$Username,

        #Sender SMTP Password
        [parameter(Mandatory=$true)]
        [securestring]$Password,

        #SMTP server name
        [parameter(Mandatory=$true)]
        [string]$SmtpServer,

        #SMTP port
        [parameter(Mandatory=$true)]
        [string]$SmtpPort,

        [parameter(Mandatory=$true)]
        [string]$AttachmentPath,

        [parameter(Mandatory=$true)]
        [string]$Body,

        [parameter(Mandatory=$true)]
        [string]$Subject
    )

    $Message = New-Object System.Net.Mail.MailMessage $MailFrom,$MailTo
    $Message.Headers.Add("X-My-Test-Header","SomeData")
    $Message.IsBodyHTML = $true
    $Message.Subject = $Subject
    $Message.Body = "<!DOCTYPE html><html><head></head><body>$Body</body></html>"
    $Message.Attachments.Add("$AttachmentPath")
    $Smtp = New-Object Net.Mail.SmtpClient($SmtpServer,$SmtpPort)
    $Smtp.EnableSsl = $true
    $Smtp.Credentials = New-Object System.Net.NetworkCredential($Username,$Password)
    $Smtp.Send($Message)
}