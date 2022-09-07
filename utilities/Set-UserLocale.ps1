param(
    
    [parameter]
    [string]$Country = 'Germany',

    [parameter]
    [int]$FirstDayOfWeek = 0,

    [parameter]
    [string]$LongDate = 'dddd, d. MMMM yyyy',

    [parameter]
    [string]$ShortDate = 'dd.MM.yyyy',

    [parameter]
    [string]$TimeFormat = 'HH:mm:ss',

    [parameter]
    [string]$YearMonth = 'MMMM yyyy'
)

$Path = 'HKCU:\Control Panel\International'

$Settings = @(

    [PSCustomObject]@{
        Name = 'iFirstDayOfWeek'
        Value = $FirstDayOfWeek
    },

    [PSCustomObject]@{
        Name = 'sCountry'
        Value = $Country
    },

    [PSCustomObject]@{
        Name = 'sLongDate'
        Value = $LongDate
    },

    [PSCustomObject]@{
        Name = 'sShortDate'
        Value = $ShortDate
    },

    [PSCustomObject]@{
        Name = 'sShortTime'
        Value = $ShortTime
    },

    [PSCustomObject]@{
        Name = 'sTimeFormat'
        Value = $TimeFormat
    },

    [PSCustomObject]@{
        Name = 'sYearMonth'
        Value = $YearMonth
    }

)

foreach($Setting in $Settings)
{
    Set-ItemProperty -Path $Path -Name $Setting.Name -Value $Setting.Value
}