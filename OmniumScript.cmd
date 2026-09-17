REM Masque l'affichage automatique des commandes CMD pour garder une console lisible.
@echo off
REM Isole les variables de ce script et active les extensions modernes de CMD.
setlocal EnableExtensions
REM Donne un titre explicite a la fenetre de console.
title Assistant de configuration Windows
REM Elargit la console pour que la banniere ASCII ne soit pas repliee sur plusieurs lignes.
mode con: cols=140 lines=50 >nul 2>&1
:: Demande automatiquement les droits administrateur.
REM Teste silencieusement si le processus dispose deja des droits administrateur.
fltmc >nul 2>&1
REM Entre dans le bloc d'elevation lorsque le test administrateur a echoue.
if not "%errorlevel%"=="0" (
REM Informe l'utilisateur que Windows va demander les droits administrateur.
    echo Demande des droits administrateur...
REM Relance ce meme fichier avec les droits administrateur demandes par Windows.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
REM Ferme l'instance non elevee apres avoir lance l'instance administrateur.
    exit /b
REM Ferme le bloc conditionnel CMD precedent.
)
REM Place le chemin absolu du fichier hybride dans une variable transmise a PowerShell.
set "CONFIG_SCRIPT=%~f0"
REM Lit ce fichier, extrait tout ce qui suit le dernier marqueur PowerShell puis execute ce bloc integre.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$raw = [IO.File]::ReadAllText($env:CONFIG_SCRIPT); $marker = '# POWERSHELL_PAYLOAD'; $code = $raw.Substring($raw.LastIndexOf($marker) + $marker.Length); & ([ScriptBlock]::Create($code))"
REM Memorise le code de sortie renvoye par la partie PowerShell.
set "RESULTAT=%errorlevel%"
REM Affiche une ligne vide pour aerer la sortie.
echo.
REM Signale une sortie anormale de PowerShell sans fermer immediatement la fenetre.
if not "%RESULTAT%"=="0" echo Le script s'est termine avec une ou plusieurs erreurs.
REM Attend une touche afin que l'utilisateur puisse lire le resultat final.
pause
REM Termine le fichier CMD avec le meme code retour que PowerShell.
exit /b %RESULTAT%
REM Le marqueur suivant permet au lanceur CMD de trouver le debut exact du code PowerShell integre.
# POWERSHELL_PAYLOAD
# Le commentaire precedent est lu uniquement par CMD ; cette ligne marque le debut de la charge PowerShell.
# Transforme les erreurs PowerShell recuperables en exceptions afin que les blocs catch puissent les signaler.
$ErrorActionPreference = 'Stop'
# Initialise ou met a jour le compteur global des etapes en erreur.
$script:ErrorCount = 0
# Declare la fonction Write-Ok, reutilisee plus loin par l'assistant.
function Write-Ok([string]$Message) {
    # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
    Write-Host "[OK] $Message" -ForegroundColor Green
# Ferme le bloc PowerShell ouvert precedemment.
}
# Declare la fonction Write-StepError, reutilisee plus loin par l'assistant.
function Write-StepError([string]$Step, [object]$ErrorObject) {
    # Initialise ou met a jour le compteur global des etapes en erreur.
    $script:ErrorCount++
    # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
    Write-Host "[ECHEC] $Step n'a pas fonctionne." -ForegroundColor Red
    # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
    if ($null -ne $ErrorObject -and $ErrorObject.Exception.Message) {
        # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
        Write-Host "Message d'erreur : $($ErrorObject.Exception.Message)" -ForegroundColor Red
    # Ferme le bloc PowerShell ouvert precedemment.
    }
# Ferme le bloc PowerShell ouvert precedemment.
}
# Declare la fonction Invoke-SafeStage, reutilisee plus loin par l'assistant.
function Invoke-SafeStage([string]$Name, [scriptblock]$Action) {
    # Debute un bloc protege dont les erreurs seront interceptees.
    try {
        # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
        & $Action
    # Intercepte l'erreur du bloc precedent et la transmet au mecanisme d'affichage sans arreter tout le script.
    } catch {
        # Enregistre et affiche l'echec sans interrompre les etapes suivantes.
        Write-StepError $Name $_
    # Debute le nettoyage execute dans tous les cas, succes comme echec.
    } finally {
        # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
        Write-Host "Poursuite vers l'etape suivante..." -ForegroundColor DarkGray
    # Ferme le bloc PowerShell ouvert precedemment.
    }
# Ferme le bloc PowerShell ouvert precedemment.
}
# Declare la fonction Read-YesNo, reutilisee plus loin par l'assistant.
function Read-YesNo([string]$Question) {
    # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
    while ($true) {
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $answer = (Read-Host "$Question (Y/N, Q pour quitter cette etape)").Trim().ToUpperInvariant()
        # Ouvre une structure de controle utilisee pour repeter ou choisir une action.
        switch ($answer) {
            # Delimite la structure PowerShell commencee par les lignes precedentes.
            { $_ -in @('Y', 'YES') } { return $true }
            # Delimite la structure PowerShell commencee par les lignes precedentes.
            { $_ -in @('N', 'NON', 'NO') } { return $false }
            # Delimite la structure PowerShell commencee par les lignes precedentes.
            { $_ -in @('Q', 'QUIT', 'EXIT') } { return $null }
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            default { Write-Host "Reponse invalide. Entrez Y, N ou Q." -ForegroundColor Yellow }
        # Ferme le bloc PowerShell ouvert precedemment.
        }
    # Ferme le bloc PowerShell ouvert precedemment.
    }
# Ferme le bloc PowerShell ouvert precedemment.
}
# Declare la fonction Read-Required, reutilisee plus loin par l'assistant.
function Read-Required([string]$Prompt) {
    # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
    while ($true) {
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $value = (Read-Host "$Prompt (Q pour annuler)").Trim()
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($value -match '^(?i:q|quit|exit)$') { return $null }
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($value) { return $value }
        # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
        Write-Host "Cette valeur est obligatoire." -ForegroundColor Yellow
    # Ferme le bloc PowerShell ouvert precedemment.
    }
# Ferme le bloc PowerShell ouvert precedemment.
}
# Declare la fonction Test-IPv4, reutilisee plus loin par l'assistant.
function Test-IPv4([string]$Address) {
    # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
    $parsed = $null
    # Renvoie immediatement le resultat indique a la fonction appelante.
    return [System.Net.IPAddress]::TryParse($Address, [ref]$parsed) -and
           # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
           $parsed.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork
# Ferme le bloc PowerShell ouvert precedemment.
}
# Declare la fonction Convert-MaskToPrefix, reutilisee plus loin par l'assistant.
function Convert-MaskToPrefix([string]$Mask) {
    # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
    if ($Mask -match '^\d{1,2}$') {
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $prefix = [int]$Mask
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($prefix -ge 0 -and $prefix -le 32) { return $prefix }
        # Declenche une erreur explicite avec un message comprehensible lorsque la verification echoue.
        throw "Le prefixe CIDR doit etre compris entre 0 et 32."
    # Ferme le bloc PowerShell ouvert precedemment.
    }
    # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
    if (-not (Test-IPv4 $Mask)) { throw "Le masque IPv4 est invalide." }
    # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
    $bits = ($Mask.Split('.') | ForEach-Object {
        # Appelle la methode .NET indiquee pour convertir, verifier ou effacer une donnee en memoire.
        [Convert]::ToString([int]$_, 2).PadLeft(8, '0')
    # Delimite la structure PowerShell commencee par les lignes precedentes.
    }) -join ''
    # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
    if ($bits -notmatch '^1*0*$') { throw "Le masque n'est pas contigu." }
    # Renvoie immediatement le resultat indique a la fonction appelante.
    return ($bits.ToCharArray() | Where-Object { $_ -eq '1' }).Count
# Ferme le bloc PowerShell ouvert precedemment.
}
# Declare la fonction Configure-BaseSettings, qui demande une autorisation avant toute modification generale.
function Configure-BaseSettings {
    # Affiche le titre de l'etape et les valeurs qui seraient appliquees par defaut.
    Write-Host "`n--- Reglages generaux proposes ---" -ForegroundColor Cyan
    # Presente chaque changement avant de demander une decision a l'utilisateur.
    Write-Host "  UAC                         = Ne jamais avertir"
    # Presente la valeur par defaut du demarrage rapide.
    Write-Host "  Demarrage rapide            = Desactive"
    # Presente la valeur par defaut de la veille sur secteur.
    Write-Host "  Veille sur secteur          = Jamais (0 minute)"
    # Presente la valeur par defaut de la veille sur batterie.
    Write-Host "  Veille sur batterie         = Jamais (0 minute)"
    # Presente la valeur par defaut de l'hibernation sur secteur.
    Write-Host "  Hibernation sur secteur     = Jamais (0 minute)"
    # Presente la valeur par defaut de l'hibernation sur batterie.
    Write-Host "  Hibernation sur batterie    = Jamais (0 minute)"
    # Presente le delai par defaut d'extinction de l'ecran sur secteur.
    Write-Host "  Ecran sur secteur           = 60 minutes"
    # Presente le delai par defaut d'extinction de l'ecran sur batterie.
    Write-Host "  Ecran sur batterie          = 60 minutes"
    # Presente la categorie reseau Ethernet proposee.
    Write-Host "  Profil reseau Ethernet      = Prive"
    # Demande Y pour appliquer, N pour ignorer ou E pour modifier les valeurs avant application.
    while ($true) {
        # Lit et normalise la reponse afin d'accepter les lettres minuscules ou majuscules.
        $mode = (Read-Host "Choisissez Y = oui, N = non, E = modifier").Trim().ToUpperInvariant()
        # Quitte la boucle uniquement pour une reponse reconnue.
        if ($mode -in @('Y', 'N', 'E')) { break }
        # Explique les choix lorsque la saisie est invalide.
        Write-Host "Reponse invalide. Entrez Y, N ou E." -ForegroundColor Yellow
    # Ferme la boucle de validation du choix principal.
    }
    # Ignore toute l'etape sans effectuer de modification si l'utilisateur choisit N.
    if ($mode -eq 'N') {
        # Confirme explicitement que les reglages generaux restent intacts.
        Write-Host "Reglages generaux ignores : aucune modification appliquee." -ForegroundColor DarkGray
        # Revient a l'assistant principal.
        return
    # Ferme la branche correspondant au refus.
    }
    # Initialise toutes les valeurs avec les valeurs par defaut annoncees.
    $settings = [ordered]@{ Uac = 'Jamais'; FastStartup = 'Desactive'; StandbyAC = 0; StandbyDC = 0; HibernateAC = 0; HibernateDC = 0; MonitorAC = 60; MonitorDC = 60; Ethernet = 'Private' }
    # Permet de modifier chaque valeur lorsque l'utilisateur choisit E.
    if ($mode -eq 'E') {
        # Informe sur les commandes disponibles pendant l'edition.
        Write-Host "`nEdition : appuyez sur Entree pour garder la valeur, S pour ignorer ce parametre, Q pour annuler toute l'etape." -ForegroundColor Yellow
        # Definit les questions, valeurs par defaut et valeurs autorisees pour les options textuelles.
        $textPrompts = @(
            # Decrit le choix UAC et ses deux niveaux proposes.
            @{ Key = 'Uac'; Label = 'UAC'; Default = 'Jamais'; Allowed = @('Jamais', 'Defaut') },
            # Decrit le choix du demarrage rapide.
            @{ Key = 'FastStartup'; Label = 'Demarrage rapide'; Default = 'Desactive'; Allowed = @('Desactive', 'Active') }
        # Termine le tableau des options textuelles.
        )
        # Demande successivement chaque option textuelle.
        foreach ($prompt in $textPrompts) {
            # Recommence la saisie jusqu'a obtenir une valeur valide.
            while ($true) {
                # Affiche la valeur par defaut entre crochets.
                $value = (Read-Host "$($prompt.Label) [$($prompt.Default)]").Trim()
                # Annule toute l'etape avant application si Q est saisi.
                if ($value -match '^(?i:Q|QUIT|EXIT)$') { Write-Host "Etape annulee : aucune modification appliquee." -ForegroundColor DarkGray; return }
                # Marque uniquement ce parametre comme ignore si S est saisi.
                if ($value -match '^(?i:S|SKIP)$') { $settings[$prompt.Key] = 'Ignorer'; break }
                # Conserve la valeur par defaut lorsque la saisie est vide.
                if (-not $value) { break }
                # Accepte une valeur textuelle autorisee sans tenir compte de la casse.
                $match = $prompt.Allowed | Where-Object { $_ -eq $value }
                # Enregistre la valeur normalisee si elle est valide.
                if ($match) { $settings[$prompt.Key] = @($match)[0]; break }
                # Affiche les valeurs acceptables avant de redemander.
                Write-Host "Valeurs acceptees : $($prompt.Allowed -join ', '), S ou Q." -ForegroundColor Yellow
            # Ferme la boucle de saisie de cette option.
            }
        # Passe a l'option textuelle suivante.
        }
        # Definit les six delais configurables, exprimes en minutes.
        $numberPrompts = @(
            # Decrit le delai de veille sur secteur.
            @{ Key = 'StandbyAC'; Label = 'Veille sur secteur en minutes'; Default = 0 },
            # Decrit le delai de veille sur batterie.
            @{ Key = 'StandbyDC'; Label = 'Veille sur batterie en minutes'; Default = 0 },
            # Decrit le delai d'hibernation sur secteur.
            @{ Key = 'HibernateAC'; Label = 'Hibernation sur secteur en minutes'; Default = 0 },
            # Decrit le delai d'hibernation sur batterie.
            @{ Key = 'HibernateDC'; Label = 'Hibernation sur batterie en minutes'; Default = 0 },
            # Decrit le delai d'extinction de l'ecran sur secteur.
            @{ Key = 'MonitorAC'; Label = 'Ecran sur secteur en minutes'; Default = 60 },
            # Decrit le delai d'extinction de l'ecran sur batterie.
            @{ Key = 'MonitorDC'; Label = 'Ecran sur batterie en minutes'; Default = 60 }
        # Termine le tableau des delais.
        )
        # Demande successivement chaque delai numerique.
        foreach ($prompt in $numberPrompts) {
            # Recommence tant que la saisie n'est pas un entier positif, S ou Q.
            while ($true) {
                # Affiche le delai par defaut entre crochets.
                $value = (Read-Host "$($prompt.Label) [$($prompt.Default)]").Trim()
                # Annule toute l'etape sans rien appliquer lorsque Q est saisi.
                if ($value -match '^(?i:Q|QUIT|EXIT)$') { Write-Host "Etape annulee : aucune modification appliquee." -ForegroundColor DarkGray; return }
                # Ignore uniquement le delai courant lorsque S est saisi.
                if ($value -match '^(?i:S|SKIP)$') { $settings[$prompt.Key] = $null; break }
                # Garde la valeur par defaut lorsque l'utilisateur appuie simplement sur Entree.
                if (-not $value) { break }
                # Prepare une variable entiere recevant le resultat de la conversion.
                $minutes = 0
                # Accepte uniquement un nombre entier compris entre 0 et 99999 minutes.
                if ([int]::TryParse($value, [ref]$minutes) -and $minutes -ge 0 -and $minutes -le 99999) { $settings[$prompt.Key] = $minutes; break }
                # Explique la plage permise avant une nouvelle saisie.
                Write-Host "Entrez un nombre de 0 a 99999, S ou Q." -ForegroundColor Yellow
            # Ferme la boucle de saisie du delai courant.
            }
        # Passe au delai suivant.
        }
        # Demande la categorie du profil Ethernet en dernier.
        while ($true) {
            # Affiche Private comme valeur par defaut.
            $value = (Read-Host "Profil Ethernet : Private ou Public [Private]").Trim()
            # Annule toute l'etape si l'utilisateur saisit Q.
            if ($value -match '^(?i:Q|QUIT|EXIT)$') { Write-Host "Etape annulee : aucune modification appliquee." -ForegroundColor DarkGray; return }
            # Ignore uniquement la categorie Ethernet si S est saisi.
            if ($value -match '^(?i:S|SKIP)$') { $settings.Ethernet = 'Ignorer'; break }
            # Conserve Private lorsque la saisie est vide.
            if (-not $value) { break }
            # Accepte les deux categories configurables par Windows.
            if ($value -match '^(?i:Private|Public)$') { $settings.Ethernet = if ($value -match '^(?i:Private)$') { 'Private' } else { 'Public' }; break }
            # Signale une valeur non reconnue.
            Write-Host "Entrez Private, Public, S ou Q." -ForegroundColor Yellow
        # Ferme la saisie de la categorie Ethernet.
        }
        # Affiche un recapitulatif complet des valeurs editees avant toute modification.
        Write-Host "`nValeurs selectionnees :" -ForegroundColor Cyan
        # Affiche chaque paire parametre-valeur, en remplacant null par Ignorer.
        foreach ($entry in $settings.GetEnumerator()) { Write-Host ("  {0,-15} = {1}" -f $entry.Key, $(if ($null -eq $entry.Value) { 'Ignorer' } else { $entry.Value })) }
        # Demande une confirmation finale apres l'edition.
        $confirm = Read-YesNo "Appliquer exactement ces valeurs ?"
        # Quitte sans modification si la confirmation n'est pas positive.
        if ($confirm -ne $true) { Write-Host "Etape annulee : aucune modification appliquee." -ForegroundColor DarkGray; return }
    # Ferme le mode edition.
    }
    # Applique l'UAC uniquement si ce parametre n'a pas ete ignore.
    if ($settings.Uac -ne 'Ignorer') {
        # Protege ce reglage afin qu'un echec n'arrete pas les suivants.
        try {
            # Pointe vers la cle systeme contenant les reglages UAC.
            $uacPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
            # Utilise 0/0 pour Ne jamais avertir ou 5/1 pour le niveau Windows par defaut.
            $uacValues = if ($settings.Uac -eq 'Jamais') { @(0, 0) } else { @(5, 1) }
            # Configure le comportement des demandes administrateur.
            Set-ItemProperty -Path $uacPath -Name ConsentPromptBehaviorAdmin -Type DWord -Value $uacValues[0]
            # Configure l'utilisation du bureau securise pour les demandes UAC.
            Set-ItemProperty -Path $uacPath -Name PromptOnSecureDesktop -Type DWord -Value $uacValues[1]
            # Confirme la valeur appliquee.
            Write-Ok "UAC configure sur '$($settings.Uac)'"
        # Signale l'erreur puis continue avec le demarrage rapide.
        } catch { Write-StepError "Le reglage du controle des comptes utilisateur" $_ }
    # Ferme l'application conditionnelle de l'UAC.
    }
    # Applique le demarrage rapide uniquement s'il n'a pas ete ignore.
    if ($settings.FastStartup -ne 'Ignorer') {
        # Protege l'ecriture de la valeur de Registre correspondante.
        try {
            # Convertit Active/Desactive en valeur numerique 1/0 attendue par Windows.
            $fastValue = if ($settings.FastStartup -eq 'Active') { 1 } else { 0 }
            # Ecrit le choix dans la configuration d'alimentation de Windows.
            Set-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name HiberbootEnabled -Type DWord -Value $fastValue
            # Confirme la valeur appliquee.
            Write-Ok "Demarrage rapide : $($settings.FastStartup)"
        # Signale l'erreur sans arreter le script.
        } catch { Write-StepError "Le reglage du demarrage rapide" $_ }
    # Ferme l'application conditionnelle du demarrage rapide.
    }
    # Associe chaque delai non ignore a la commande powercfg correspondante.
    $powerSettings = @(
        # Associe la veille sur secteur.
        @{ Name = 'Veille sur secteur'; Argument = 'standby-timeout-ac'; Value = $settings.StandbyAC },
        # Associe la veille sur batterie.
        @{ Name = 'Veille sur batterie'; Argument = 'standby-timeout-dc'; Value = $settings.StandbyDC },
        # Associe l'hibernation sur secteur.
        @{ Name = 'Hibernation sur secteur'; Argument = 'hibernate-timeout-ac'; Value = $settings.HibernateAC },
        # Associe l'hibernation sur batterie.
        @{ Name = 'Hibernation sur batterie'; Argument = 'hibernate-timeout-dc'; Value = $settings.HibernateDC },
        # Associe l'ecran sur secteur.
        @{ Name = 'Ecran sur secteur'; Argument = 'monitor-timeout-ac'; Value = $settings.MonitorAC },
        # Associe l'ecran sur batterie.
        @{ Name = 'Ecran sur batterie'; Argument = 'monitor-timeout-dc'; Value = $settings.MonitorDC }
    # Termine le tableau des commandes d'alimentation.
    )
    # Applique chaque delai independamment pour continuer en cas d'erreur ponctuelle.
    foreach ($powerSetting in $powerSettings) {
        # Saute les valeurs explicitement ignorees en mode edition.
        if ($null -eq $powerSetting.Value) { continue }
        # Protege l'appel a powercfg.
        try {
            # Transmet a powercfg le nom du reglage et le nombre de minutes choisi.
            & powercfg.exe /change $powerSetting.Argument $powerSetting.Value
            # Transforme un code retour non nul en erreur explicite.
            if ($LASTEXITCODE) { throw "powercfg a retourne le code $LASTEXITCODE." }
            # Confirme le delai applique.
            Write-Ok "$($powerSetting.Name) : $($powerSetting.Value) minute(s)"
        # Signale l'echec de ce seul delai puis poursuit.
        } catch { Write-StepError "Le reglage '$($powerSetting.Name)'" $_ }
    # Passe au reglage d'alimentation suivant.
    }
    # Modifie le profil Ethernet uniquement si ce parametre n'a pas ete ignore.
    if ($settings.Ethernet -ne 'Ignorer') {
        # Protege la detection et la modification des profils Ethernet.
        try {
            # Recueille uniquement les profils appartenant a une carte Ethernet physique.
            $wiredProfiles = @(foreach ($profile in @(Get-NetConnectionProfile)) { $adapter = Get-NetAdapter -InterfaceIndex $profile.InterfaceIndex -ErrorAction SilentlyContinue; if ($null -ne $adapter) { $adapterText = "$($adapter.Name) $($adapter.InterfaceDescription) $($adapter.MediaType) $($adapter.NdisPhysicalMedium)"; if ($adapterText -match '(?i)Ethernet|802\.3' -and $adapterText -notmatch '(?i)Wi-?Fi|Wireless|WLAN|802\.11') { $profile } } })
            # Refuse d'annoncer un succes lorsqu'aucun profil Ethernet n'a ete trouve.
            if ($wiredProfiles.Count -eq 0) { throw "Aucun profil Ethernet actif n'a ete detecte." }
            # Applique la categorie choisie a chaque profil Ethernet non gere par un domaine.
            foreach ($profile in $wiredProfiles) { if ($profile.NetworkCategory -eq 'DomainAuthenticated') { Write-Host "[AVERTISSEMENT] '$($profile.Name)' est gere par un domaine et reste inchange." -ForegroundColor Yellow; continue }; Set-NetConnectionProfile -InterfaceIndex $profile.InterfaceIndex -NetworkCategory $settings.Ethernet -ErrorAction Stop }
            # Confirme la categorie demandee.
            Write-Ok "Profil Ethernet demande : $($settings.Ethernet)"
        # Signale l'erreur sans interrompre les autres etapes de l'assistant.
        } catch { Write-StepError "Le reglage du profil Ethernet" $_ }
    # Ferme l'application conditionnelle du profil Ethernet.
    }
# Ferme la fonction des reglages generaux.
}
# Declare la fonction Configure-ComputerName, reutilisee plus loin par l'assistant.
function Configure-ComputerName {
    # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
    Write-Host "`n--- Nom du PC ---" -ForegroundColor Cyan
    # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
    $choice = Read-YesNo "Voulez-vous changer le nom du PC ?"
    # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
    if ($null -eq $choice -or -not $choice) { return }
    # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
    while ($true) {
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $newName = Read-Required "Nouveau nom du PC (15 caracteres maximum)"
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($null -eq $newName) { return }
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($newName.Length -le 15 -and $newName -match '^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$' -and
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            $newName -notmatch '^\d+$') { break }
        # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
        Write-Host "Nom invalide : lettres, chiffres et tirets uniquement, sans tiret au debut/fin, et pas uniquement des chiffres." -ForegroundColor Yellow
    # Ferme le bloc PowerShell ouvert precedemment.
    }
    # Debute un bloc protege dont les erreurs seront interceptees.
    try {
        # Programme le nouveau nom Windows du poste, effectif apres redemarrage.
        Rename-Computer -NewName $newName -Force
        # Affiche une confirmation verte pour l'operation qui vient d'etre verifiee.
        Write-Ok "Le PC sera renomme en '$newName' au prochain redemarrage"
    # Intercepte l'erreur du bloc precedent et la transmet au mecanisme d'affichage sans arreter tout le script.
    } catch { Write-StepError "Le changement du nom du PC" $_ }
# Ferme le bloc PowerShell ouvert precedemment.
}
# Declare la fonction Configure-StaticIP, reutilisee plus loin par l'assistant.
function Configure-StaticIP {
    # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
    Write-Host "`n--- Adresse IP fixe ---" -ForegroundColor Cyan
    # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
    $choice = Read-YesNo "Voulez-vous configurer une adresse IP fixe ?"
    # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
    if ($null -eq $choice -or -not $choice) { return }
    # Debute un bloc protege dont les erreurs seront interceptees.
    try {
        # Interroge la configuration reseau Windows utilisee par cette etape.
        $adapters = @(Get-NetAdapter | Where-Object {
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            $_.Status -ne 'Disabled' -and $_.HardwareInterface
        # Delimite la structure PowerShell commencee par les lignes precedentes.
        } | Sort-Object Name)
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($adapters.Count -eq 0) { throw "Aucune carte reseau utilisable n'a ete trouvee." }
        # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
        Write-Host "`nCartes reseau disponibles :"
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        for ($i = 0; $i -lt $adapters.Count; $i++) {
            # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
            Write-Host ("  [{0}] {1} - {2} - Etat : {3}" -f ($i + 1), $adapters[$i].Name,
                # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
                $adapters[$i].InterfaceDescription, $adapters[$i].Status)
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        while ($true) {
            # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
            $selection = Read-Required "Numero de la carte reseau"
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if ($null -eq $selection) { return }
            # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
            $number = 0
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if ([int]::TryParse($selection, [ref]$number) -and $number -ge 1 -and $number -le $adapters.Count) {
                # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
                $adapter = $adapters[$number - 1]
                # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
                break
            # Ferme le bloc PowerShell ouvert precedemment.
            }
            # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
            Write-Host "Numero de carte invalide." -ForegroundColor Yellow
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        while ($true) {
            # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
            $ip = Read-Required "Adresse IPv4"
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if ($null -eq $ip) { return }
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if (Test-IPv4 $ip) { break }
            # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
            Write-Host "Adresse IPv4 invalide." -ForegroundColor Yellow
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        while ($true) {
            # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
            $mask = Read-Required "Masque de sous-reseau (exemple 255.255.255.0 ou 24)"
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if ($null -eq $mask) { return }
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            try { $prefix = Convert-MaskToPrefix $mask; break }
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            catch { Write-Host $_.Exception.Message -ForegroundColor Yellow }
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        while ($true) {
            # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
            $gateway = Read-Required "Passerelle par defaut"
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if ($null -eq $gateway) { return }
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if (Test-IPv4 $gateway) { break }
            # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
            Write-Host "Passerelle IPv4 invalide." -ForegroundColor Yellow
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $changeDns = Read-YesNo "Voulez-vous modifier les DNS ?"
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($null -eq $changeDns) { return }
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $dnsServers = $null
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($changeDns) {
            # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
            Write-Host "Valeurs par defaut : DNS principal 8.8.8.8, DNS secondaire = IP de la passerelle."
            # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
            $dns1 = (Read-Host "DNS principal [8.8.8.8] (Q pour annuler)").Trim()
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if ($dns1 -match '^(?i:q|quit|exit)$') { return }
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if (-not $dns1) { $dns1 = '8.8.8.8' }
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if (-not (Test-IPv4 $dns1)) { throw "Le DNS principal '$dns1' est invalide." }
            # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
            $dns2 = (Read-Host "DNS secondaire [$gateway] (Q pour annuler)").Trim()
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if ($dns2 -match '^(?i:q|quit|exit)$') { return }
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if (-not $dns2) { $dns2 = $gateway }
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if (-not (Test-IPv4 $dns2)) { throw "Le DNS secondaire '$dns2' est invalide." }
            # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
            $dnsServers = @($dns1, $dns2) | Select-Object -Unique
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $confirm = Read-YesNo "Appliquer l'IP $ip/$prefix avec la passerelle $gateway sur '$($adapter.Name)' ?"
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($null -eq $confirm -or -not $confirm) { return }
        # Modifie le parametre reseau cible avec les valeurs validees auparavant.
        Set-NetIPInterface -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -Dhcp Disabled
        # Interroge la configuration reseau Windows utilisee par cette etape.
        Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            Where-Object { $_.PrefixOrigin -ne 'WellKnown' } |
            # Supprime l'ancien parametre reseau devenu incompatible avec la nouvelle configuration.
            Remove-NetIPAddress -Confirm:$false
        # Interroge la configuration reseau Windows utilisee par cette etape.
        Get-NetRoute -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -DestinationPrefix '0.0.0.0/0' `
            -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false
        # Cree la nouvelle configuration IPv4 statique demandee.
        New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $ip -PrefixLength $prefix `
            -DefaultGateway $gateway | Out-Null
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($changeDns) {
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $dnsServers
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Affiche une confirmation verte pour l'operation qui vient d'etre verifiee.
        Write-Ok "Adresse IP fixe configuree sur '$($adapter.Name)'"
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($changeDns) { Write-Ok "Serveurs DNS configures : $($dnsServers -join ', ')" }
        # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
        else { Write-Host "Les serveurs DNS n'ont pas ete modifies." }
    # Intercepte l'erreur du bloc precedent et la transmet au mecanisme d'affichage sans arreter tout le script.
    } catch { Write-StepError "La configuration de l'adresse IP fixe" $_ }
# Ferme le bloc PowerShell ouvert precedemment.
}
# Declare la fonction Configure-LocalPassword, reutilisee plus loin par l'assistant.
function Configure-LocalPassword {
    # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
    Write-Host "`n--- Mot de passe du poste ---" -ForegroundColor Cyan
    # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
    $choice = Read-YesNo "Voulez-vous changer le mot de passe d'un compte local ?"
    # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
    if ($null -eq $choice -or -not $choice) { return }
    # Debute un bloc protege dont les erreurs seront interceptees.
    try {
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $users = @(Get-LocalUser | Where-Object { $_.Enabled } | Sort-Object Name)
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($users.Count -eq 0) { throw "Aucun compte local actif n'a ete trouve." }
        # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
        Write-Host "`nComptes locaux actifs :"
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        for ($i = 0; $i -lt $users.Count; $i++) {
            # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
            Write-Host ("  [{0}] {1}" -f ($i + 1), $users[$i].Name)
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        while ($true) {
            # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
            $selection = Read-Required "Numero du compte"
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if ($null -eq $selection) { return }
            # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
            $number = 0
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if ([int]::TryParse($selection, [ref]$number) -and $number -ge 1 -and $number -le $users.Count) {
                # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
                $user = $users[$number - 1]
                # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
                break
            # Ferme le bloc PowerShell ouvert precedemment.
            }
            # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
            Write-Host "Numero de compte invalide." -ForegroundColor Yellow
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
        Write-Host "Saisissez le nouveau mot de passe (la saisie sera masquee)."
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $password1 = Read-Host "Nouveau mot de passe" -AsSecureString
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $password2 = Read-Host "Confirmez le mot de passe" -AsSecureString
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $bstr1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password1)
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $bstr2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password2)
        # Debute un bloc protege dont les erreurs seront interceptees.
        try {
            # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
            $plain1 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr1)
            # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
            $plain2 = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr2)
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if ($plain1 -ne $plain2) { throw "Les deux mots de passe ne correspondent pas." }
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if ([string]::IsNullOrEmpty($plain1)) { throw "Le mot de passe ne peut pas etre vide." }
        # Debute le nettoyage execute dans tous les cas, succes comme echec.
        } finally {
            # Appelle la methode .NET indiquee pour convertir, verifier ou effacer une donnee en memoire.
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1)
            # Appelle la methode .NET indiquee pour convertir, verifier ou effacer une donnee en memoire.
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2)
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            Remove-Variable plain1, plain2 -ErrorAction SilentlyContinue
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Applique au compte local selectionne le mot de passe saisi de maniere masquee.
        Set-LocalUser -Name $user.Name -Password $password1
        # Affiche une confirmation verte pour l'operation qui vient d'etre verifiee.
        Write-Ok "Mot de passe du compte '$($user.Name)' modifie"
    # Intercepte l'erreur du bloc precedent et la transmet au mecanisme d'affichage sans arreter tout le script.
    } catch { Write-StepError "Le changement du mot de passe" $_ }
# Ferme le bloc PowerShell ouvert precedemment.
}
# Declare la fonction Configure-Desktop, reutilisee plus loin par l'assistant.
function Configure-Desktop {
    # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
    Write-Host "`n--- Nettoyage du bureau ---" -ForegroundColor Cyan
    # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
    $choice = Read-YesNo "Voulez-vous nettoyer le bureau et configurer ses icones ?"
    # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
    if ($null -eq $choice -or -not $choice) {
        # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
        Write-Host "Bureau laisse entierement intact." -ForegroundColor DarkGray
        # Renvoie immediatement le resultat indique a la fonction appelante.
        return
    # Ferme le bloc PowerShell ouvert precedemment.
    }
    # Debute un bloc protege dont les erreurs seront interceptees.
    try {
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $sessionId = [Diagnostics.Process]::GetCurrentProcess().SessionId
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $explorerProcess = Get-CimInstance Win32_Process -Filter "Name='explorer.exe'" |
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            Where-Object { $_.SessionId -eq $sessionId } |
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            Select-Object -First 1
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($null -eq $explorerProcess) {
            # Declenche une erreur explicite avec un message comprehensible lorsque la verification echoue.
            throw "Impossible d'identifier l'utilisateur connecte via explorer.exe."
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $owner = Invoke-CimMethod -InputObject $explorerProcess -MethodName GetOwner
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($owner.ReturnValue -ne 0) {
            # Declenche une erreur explicite avec un message comprehensible lorsque la verification echoue.
            throw "Impossible de trouver le proprietaire de la session (code $($owner.ReturnValue))."
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $account = New-Object Security.Principal.NTAccount($owner.Domain, $owner.User)
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $userSid = $account.Translate([Security.Principal.SecurityIdentifier]).Value
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $profilePath = (Get-ItemProperty `
            -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$userSid" `
            -Name ProfileImagePath).ProfileImagePath
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $profilePath = [Environment]::ExpandEnvironmentVariables($profilePath)
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $shellFoldersPath = "Registry::HKEY_USERS\$userSid\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $desktopSetting = (Get-ItemProperty -Path $shellFoldersPath -Name Desktop).Desktop
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $userDesktop = $desktopSetting.Replace('%USERPROFILE%', $profilePath)
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $userDesktop = [Environment]::ExpandEnvironmentVariables($userDesktop)
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $backupRoot = Join-Path $profilePath "Sauvegarde_Bureau_$stamp"
        # Cree la cle de Registre ou le dossier requis s'il n'existe pas encore.
        New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $moveErrors = [Collections.Generic.List[string]]::new()
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $desktopSources = @(
            # Appelle la methode .NET indiquee pour convertir, verifier ou effacer une donnee en memoire.
            [PSCustomObject]@{ Path = $userDesktop; Name = 'Bureau_Utilisateur' },
            # Appelle la methode .NET indiquee pour convertir, verifier ou effacer une donnee en memoire.
            [PSCustomObject]@{ Path = $publicDesktop; Name = 'Bureau_Public' }
        # Delimite la structure PowerShell commencee par les lignes precedentes.
        )
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        foreach ($source in $desktopSources) {
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            if (-not (Test-Path -LiteralPath $source.Path)) { continue }
            # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
            $destination = Join-Path $backupRoot $source.Name
            # Cree la cle de Registre ou le dossier requis s'il n'existe pas encore.
            New-Item -ItemType Directory -Path $destination -Force | Out-Null
            # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
            foreach ($item in @(Get-ChildItem -LiteralPath $source.Path -Force |
                # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
                Where-Object { $_.Name -ne 'desktop.ini' })) {
                # Debute un bloc protege dont les erreurs seront interceptees.
                try {
                    # Deplace l'element du bureau vers la sauvegarde recuperable au lieu de le supprimer.
                    Move-Item -LiteralPath $item.FullName -Destination $destination -ErrorAction Stop
                # Intercepte l'erreur du bloc precedent et la transmet au mecanisme d'affichage sans arreter tout le script.
                } catch {
                    # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
                    $moveErrors.Add("$($item.FullName) : $($_.Exception.Message)")
                # Ferme le bloc PowerShell ouvert precedemment.
                }
            # Ferme le bloc PowerShell ouvert precedemment.
            }
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # 0 = afficher l'icone systeme sur le bureau.
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $iconPath = "Registry::HKEY_USERS\$userSid\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons"
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $newStartPanelPath = Join-Path $iconPath 'NewStartPanel'
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $classicStartMenuPath = Join-Path $iconPath 'ClassicStartMenu'
        # Cree la cle de Registre ou le dossier requis s'il n'existe pas encore.
        New-Item -Path $newStartPanelPath -Force | Out-Null
        # Cree la cle de Registre ou le dossier requis s'il n'existe pas encore.
        New-Item -Path $classicStartMenuPath -Force | Out-Null
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $iconsToShow = @(
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            '{645FF040-5081-101B-9F08-00AA002F954E}', # Corbeille
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            '{20D04FE0-3AEA-1069-A2D8-08002B30309D}', # Ce PC
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            '{59031a47-3f72-44a7-89c5-5595fe6b30ee}'  # Fichiers de l'utilisateur
        # Delimite la structure PowerShell commencee par les lignes precedentes.
        )
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        foreach ($icon in $iconsToShow) {
            # Ecrit la valeur de Registre indiquee afin d'appliquer le parametre Windows concerne.
            Set-ItemProperty -Path $newStartPanelPath -Name $icon -Type DWord -Value 0
            # Ecrit la valeur de Registre indiquee afin d'appliquer le parametre Windows concerne.
            Set-ItemProperty -Path $classicStartMenuPath -Name $icon -Type DWord -Value 0
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Calcule ou memorise la valeur necessaire aux instructions qui suivent.
        $iconsToHide = @(
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            '{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}', # Reseau
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            '{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}', # Panneau de configuration
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            '{031E4825-7B94-4DC3-B131-E946B44C8DD5}', # Bibliotheques
            # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
            '{018D5C66-4533-4307-9B53-224DE2ED1FE6}'  # OneDrive
        # Delimite la structure PowerShell commencee par les lignes precedentes.
        )
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        foreach ($icon in $iconsToHide) {
            # Ecrit la valeur de Registre indiquee afin d'appliquer le parametre Windows concerne.
            Set-ItemProperty -Path $newStartPanelPath -Name $icon -Type DWord -Value 1
            # Ecrit la valeur de Registre indiquee afin d'appliquer le parametre Windows concerne.
            Set-ItemProperty -Path $classicStartMenuPath -Name $icon -Type DWord -Value 1
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Debute un bloc protege dont les erreurs seront interceptees.
        try {
            # Localise ou redemarre Explorer pour rendre visibles les changements d'interface.
            Get-Process explorer -ErrorAction SilentlyContinue |
                # Execute cette partie de l'operation decrite par la fonction ou le bloc courant.
                Where-Object { $_.SessionId -eq $sessionId } |
                # Localise ou redemarre Explorer pour rendre visibles les changements d'interface.
                Stop-Process -Force -ErrorAction Stop
        # Intercepte l'erreur du bloc precedent et la transmet au mecanisme d'affichage sans arreter tout le script.
        } catch {
            # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
            Write-Host "[AVERTISSEMENT] Windows n'autorise pas l'actualisation automatique du bureau : $($_.Exception.Message)" `
                -ForegroundColor Yellow
            # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
            Write-Host "Les icones seront actualisees a la prochaine ouverture de session." `
                -ForegroundColor Yellow
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Affiche une confirmation verte pour l'operation qui vient d'etre verifiee.
        Write-Ok "Bureau nettoye ; Corbeille, Ce PC et Fichiers de l'utilisateur affiches"
        # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
        Write-Host "Sauvegarde des anciens elements : $backupRoot" -ForegroundColor Yellow
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($moveErrors.Count -gt 0) {
            # Declenche une erreur explicite avec un message comprehensible lorsque la verification echoue.
            throw "Certains elements n'ont pas pu etre deplaces :`n$($moveErrors -join "`n")"
        # Ferme le bloc PowerShell ouvert precedemment.
        }
    # Intercepte l'erreur du bloc precedent et la transmet au mecanisme d'affichage sans arreter tout le script.
    } catch { Write-StepError "Le nettoyage et la configuration des icones du bureau" $_ }
# Ferme le bloc PowerShell ouvert precedemment.
}
# Nettoie la console avant d'afficher la banniere et l'assistant.
Clear-Host
# Conserve l'ASCII art dans une chaine litterale afin que ses symboles ne soient jamais interpretes par PowerShell.
$banner = @'
  /$$$$$$                          /$$                                /$$$$$$                      /$$             /$$
 /$$__  $$                        |__/                               /$$__  $$                    |__/            | $$
| $$  \ $$ /$$$$$$/$$$$  /$$$$$$$  /$$ /$$   /$$ /$$$$$$/$$$$       | $$  \__/  /$$$$$$$  /$$$$$$  /$$  /$$$$$$  /$$$$$$
| $$  | $$| $$_  $$_  $$| $$__  $$| $$| $$  | $$| $$_  $$_  $$      |  $$$$$$  /$$_____/ /$$__  $$| $$ /$$__  $$|_  $$_/
| $$  | $$| $$ \ $$ \ $$| $$  \ $$| $$| $$  | $$| $$ \ $$ \ $$       \____  $$| $$      | $$  \__/| $$| $$  \ $$  | $$
| $$  | $$| $$ | $$ | $$| $$  | $$| $$| $$  | $$| $$ | $$ | $$       /$$  \ $$| $$      | $$      | $$| $$  | $$  | $$ /$$
|  $$$$$$/| $$ | $$ | $$| $$  | $$| $$|  $$$$$$/| $$ | $$ | $$      |  $$$$$$/|  $$$$$$$| $$      | $$| $$$$$$$/  |  $$$$/
 \______/ |__/ |__/ |__/|__/  |__/|__/ \______/ |__/ |__/ |__/       \______/  \_______/|__/      |__/| $$____/    \___/
                                                                                                    | $$
                                                                                                    | $$
                                                                                                    |__/
 /$$                          /$$$$$           /$$ /$$ /$$
| $$                         |__  $$          | $$|__/| $$
| $$$$$$$  /$$   /$$            | $$  /$$$$$$ | $$ /$$| $$
| $$__  $$| $$  | $$            | $$ |____  $$| $$| $$| $$
| $$  \ $$| $$  | $$       /$$  | $$  /$$$$$$$| $$| $$| $$
| $$  | $$| $$  | $$      | $$  | $$ /$$__  $$| $$| $$| $$
| $$$$$$$/|  $$$$$$$      |  $$$$$$/|  $$$$$$$| $$| $$| $$
|_______/  \____  $$       \______/  \_______/|__/|__/|__/
           /$$  | $$
          |  $$$$$$/
           \______/
'@
# Affiche la banniere en cyan avant le titre fonctionnel de l'assistant.
Write-Host $banner -ForegroundColor Cyan
# Affiche une ligne vide entre la banniere et le titre de l'assistant.
Write-Host ''
# Affiche a l'utilisateur le titre fonctionnel de l'assistant.
Write-Host "ASSISTANT DE CONFIGURATION WINDOWS" -ForegroundColor Cyan
# Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
Write-Host "Vous pouvez saisir Q pour annuler une procedure interactive."
# Execute l'etape nommee dans l'enveloppe de securite qui garantit la poursuite du script.
Invoke-SafeStage "Les reglages generaux" { Configure-BaseSettings }
# Execute l'etape nommee dans l'enveloppe de securite qui garantit la poursuite du script.
Invoke-SafeStage "Le nettoyage du bureau" { Configure-Desktop }
# Execute l'etape nommee dans l'enveloppe de securite qui garantit la poursuite du script.
Invoke-SafeStage "La procedure de changement du nom du PC" { Configure-ComputerName }
# Execute l'etape nommee dans l'enveloppe de securite qui garantit la poursuite du script.
Invoke-SafeStage "La procedure de configuration IP" { Configure-StaticIP }
# Execute l'etape nommee dans l'enveloppe de securite qui garantit la poursuite du script.
Invoke-SafeStage "La procedure de changement du mot de passe" { Configure-LocalPassword }
# Affiche un titre distinct afin que TeamViewer soit traite comme une etape autonome.
Write-Host "`n--- Installation de TeamViewer ---" -ForegroundColor Cyan
# Demande une autorisation explicite avant de telecharger ou installer TeamViewer.
$teamViewerChoice = Read-YesNo "Voulez-vous installer TeamViewer ?"
# Lance l'installation uniquement lorsque l'utilisateur repond Y.
if ($teamViewerChoice) {
    # Protege toute l'etape afin qu'un echec WinGet n'empeche pas les etapes suivantes.
    try {
        # Recherche winget.exe dans les commandes accessibles sur ce poste.
        $wingetCommand = Get-Command winget.exe -ErrorAction Stop
        # Informe clairement que l'identifiant choisi correspond a TeamViewer complet et non a QuickSupport.
        Write-Host "Installation de TeamViewer complet (TeamViewer.TeamViewer), pas de QuickSupport..." -ForegroundColor Cyan
        # Installe exactement le paquet complet depuis la source officielle WinGet pour l'ensemble de la machine.
        & $wingetCommand.Source install --id TeamViewer.TeamViewer --exact --source winget --scope machine --silent --disable-interactivity --accept-package-agreements --accept-source-agreements
        # Transforme tout code retour WinGet non nul en erreur explicite.
        if ($LASTEXITCODE -ne 0) { throw "WinGet a retourne le code $LASTEXITCODE." }
        # Confirme que WinGet a termine l'installation sans erreur.
        Write-Ok "TeamViewer complet installe ou deja a jour"
    # Intercepte et affiche l'erreur tout en poursuivant vers le resume.
    } catch {
        # Enregistre l'echec afin qu'il soit comptabilise dans le resume qui suit.
        Write-StepError "L'installation de TeamViewer complet" $_
    # Ferme le bloc de gestion d'erreur TeamViewer.
    }
# Traite le refus, l'annulation ou la reponse N sans lancer WinGet.
} else {
    # Confirme qu'aucun telechargement ni aucune installation TeamViewer n'a ete effectue.
    Write-Host "Installation de TeamViewer ignoree." -ForegroundColor DarkGray
# Ferme la condition d'installation TeamViewer.
}
# Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
Write-Host "`n--- Resume ---" -ForegroundColor Cyan
# Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
if ($script:ErrorCount -eq 0) {
    # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
    Write-Host "Toutes les etapes demandees se sont terminees sans erreur." -ForegroundColor Green
# Debute la branche executee lorsque la condition precedente est fausse.
} else {
    # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
    Write-Host "$script:ErrorCount etape(s) ont rencontre une erreur. Consultez les messages [ECHEC] ci-dessus." -ForegroundColor Red
# Ferme le bloc PowerShell ouvert precedemment.
}
# Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
Write-Host "Un redemarrage est recommande pour finaliser le nom du PC et les reglages Windows."
# Calcule ou memorise la valeur necessaire aux instructions qui suivent.
$restartChoice = Read-YesNo "Voulez-vous redemarrer le poste maintenant ?"
# Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
if ($restartChoice) {
    # Debute un bloc protege dont les erreurs seront interceptees.
    try {
        # Appelle l'outil Windows indique pour appliquer le reglage d'alimentation ou le redemarrage.
        & shutdown.exe /r /t 10 /c "Redemarrage demande par l'assistant de configuration Windows"
        # Evalue la condition ou parcourt la collection indiquee afin de controler le flux du script.
        if ($LASTEXITCODE) {
            # Declenche une erreur explicite avec un message comprehensible lorsque la verification echoue.
            throw "shutdown.exe a retourne le code $LASTEXITCODE."
        # Ferme le bloc PowerShell ouvert precedemment.
        }
        # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
        Write-Host "Le poste va redemarrer dans 10 secondes." -ForegroundColor Yellow
    # Intercepte l'erreur du bloc precedent et la transmet au mecanisme d'affichage sans arreter tout le script.
    } catch {
        # Enregistre et affiche l'echec sans interrompre les etapes suivantes.
        Write-StepError "Le redemarrage du poste" $_
    # Ferme le bloc PowerShell ouvert precedemment.
    }
# Debute la branche executee lorsque la condition precedente est fausse.
} else {
    # Affiche a l'utilisateur le message d'etat, d'aide ou d'avertissement indique.
    Write-Host "Redemarrage non demande. Vous pourrez redemarrer le poste plus tard." -ForegroundColor DarkGray
# Ferme le bloc PowerShell ouvert precedemment.
}
# Termine proprement la partie PowerShell avec le code indique.
exit 0
