function Get-MethodDefinition {
    param(
        [Parameter(Mandatory=$true)]
        [PSObject] $Object,

        [Parameter(Mandatory=$true)]
        [string] $MethodName
    )

    $methodOverloads = $Object.GetType().GetMethods() | Where-Object {$_.Name -eq $MethodName}

    $methodOverloads | ForEach-Object {
        $parameters = ($_.GetParameters() | ForEach-Object { $_.ParameterType.Name + " " + $_.Name }) -join ', '
        $returnType = $_.ReturnType.Name
        "$returnType $MethodName($parameters)"
    }
}