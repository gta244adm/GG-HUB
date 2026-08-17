--==============================================================
-- OFFLINE MOVESETS V5
-- JUN + SUKUNA + GAROU CÓSMICO + GOJO
--
-- PRIMEIRA EXECUÇÃO:
--   baixa e prepara tudo
--
-- PRÓXIMAS:
--   somente cache local
--
-- IMPORTANTE:
--   apague a pasta "Movesets" da versão anterior antes de usar
--==============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local ROOT = "Movesets"
local MANIFEST = ROOT .. "/manifest.lua"

local SOURCES = {
    JUN = {
        "https://pastebin.com/raw/S8WpAb5C"
    },

    SUKUNA = {
        "https://pastebin.com/raw/iW2Gg6Hh"
    },

    GAROU = {
        "https://pastebin.com/raw/JAMqGxLW"
    },

    GOJO = {
        "https://pastebin.com/raw/EHW6uehz"
    }
}

local CACHE = {}
local PATHS = {}
local Installing = false

--==============================================================
-- NOTIFY
--==============================================================

local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5
        })
    end)
end

--==============================================================
-- FILESYSTEM
--==============================================================

local function IsFile(path)
    return type(isfile) == "function" and isfile(path)
end

local function EnsureRoot()
    if type(isfolder) ~= "function"
        or type(makefolder) ~= "function"
    then
        error("Seu executor precisa suportar isfolder/makefolder.")
    end

    if not isfolder(ROOT) then
        makefolder(ROOT)
    end
end

local function Read(path)
    if not IsFile(path) then
        return nil
    end

    return readfile(path)
end

local function Write(path, data)
    writefile(path, data)
end

EnsureRoot()

--==============================================================
-- DOWNLOAD SOMENTE NA INSTALAÇÃO
--==============================================================

local function Download(url)
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok then
        error(
            "Falha HTTP:\n"
            .. tostring(url)
            .. "\n\n"
            .. tostring(result)
        )
    end

    return result
end

--==============================================================
-- BASENAME
--==============================================================

local function BaseName(url)
    local clean = tostring(url):gsub("%?.*$", "")
    local name = clean:match("/([^/]+)$")

    if not name or name == "" then
        name = "remote"
    end

    name = name:gsub("[<>:\"/\\|%?%*]", "_")

    return name
end

--==============================================================
-- HASH
--==============================================================

local function Hash(str)
    local h = 2166136261

    for i = 1, #str do
        h = bit32.bxor(h, string.byte(str, i))
        h = (h * 16777619) % 4294967296
    end

    return string.format("%08x", h)
end

--==============================================================
-- TIPO DE ASSET
--==============================================================

local function IsAsset(url)
    local x = tostring(url):lower()

    return
        x:match("%.mp3") ~= nil
        or x:match("%.wav") ~= nil
        or x:match("%.ogg") ~= nil
        or x:match("%.rbxm") ~= nil
        or x:match("%.rbxmx") ~= nil
        or x:match("%.webm") ~= nil
        or x:match("%.mp4") ~= nil
        or x:match("%.png") ~= nil
        or x:match("%.jpg") ~= nil
        or x:match("%.jpeg") ~= nil
end

--==============================================================
-- CAMINHO
--==============================================================

local function GetPath(url)
    if PATHS[url] then
        return PATHS[url]
    end

    local name = BaseName(url)

    local path

    if IsAsset(url) then
        path = ROOT .. "/" .. name
    else
        path =
            ROOT
            .. "/"
            .. Hash(url)
            .. "_"
            .. name
            .. ".lua"
    end

    PATHS[url] = path

    return path
end

--==============================================================
-- URLS
--==============================================================

local function ExtractUrls(source)

    local result = {}
    local found = {}

    local function Add(url)

        url = tostring(url)

        if found[url] then
            return
        end

        if
            url:sub(1, 8) == "https://"
            or
            url:sub(1, 7) == "http://"
        then

            found[url] = true

            table.insert(
                result,
                url
            )

        end
    end

    for url in source:gmatch(
        [["(https?://[^"]+)"]]
    ) do
        Add(url)
    end

    for url in source:gmatch(
        [['(https?://[^']+)']]
    ) do
        Add(url)
    end

    return result
end

--==============================================================
-- REGISTRAR
--==============================================================

local function Register(url, path, kind)
    CACHE[url] = {
        path = path,
        kind = kind
    }
end

--==============================================================
-- INSTALAR RECURSIVAMENTE
--==============================================================

local function InstallUrl(url, stack)

    stack = stack or {}

    if stack[url] then
        return
    end

    stack[url] = true

    local path = GetPath(url)

    if CACHE[url] and IsFile(path) then
        stack[url] = nil
        return
    end

    print(
        "[Movesets] Baixando:",
        url
    )

    local data = Download(url)

    if IsAsset(url) then

        Write(
            path,
            data
        )

        Register(
            url,
            path,
            "asset"
        )

    else

        Write(
            path,
            data
        )

        Register(
            url,
            path,
            "script"
        )

        for _, dep in ipairs(
            ExtractUrls(data)
        ) do

            local ok, err =
                pcall(
                    InstallUrl,
                    dep,
                    stack
                )

            if not ok then
                warn(
                    "[Movesets] Dependência:",
                    dep,
                    err
                )
            end

        end
    end

    stack[url] = nil
end

--==============================================================
-- REMOVE OS DOWNLOADS INTERNOS DOS MOVESSETS
--
-- Isso é o que corrige o erro das suas imagens.
--==============================================================

local function StripInternalDownloads(source)

    local lines = {}

    local skipIf = false

    for line in source:gmatch("[^\r\n]*") do

        -- ------------------------------------------------------
        -- if not isfile("arquivo") then
        -- writefile(...)
        -- end
        -- ------------------------------------------------------

        if line:match(
            "^%s*if%s+not%s+isfile%s*%("
        ) then

            skipIf = true

        elseif skipIf
            and line:match("^%s*end%s*$")
        then

            skipIf = false

        elseif skipIf then

            -- ignora o corpo

        elseif line:match(
            "^%s*writefile%s*%("
        )
        and line:match(
            "HttpGet"
        )
        then

            -- remove download

        elseif line:match(
            "^%s*game:GetService%s*%("
        )
        then

            table.insert(
                lines,
                line
            )

        else

            table.insert(
                lines,
                line
            )

        end

    end

    return table.concat(
        lines,
        "\n"
    )
end

--==============================================================
-- TROCA ASSETS
--==============================================================

local function PatchAssets(source)

    source =
        source:gsub(
            'getcustomasset%s*%(%s*["\']([^"\']+)["\']%s*%)',
            function(name)

                if name:sub(1, #ROOT + 1) ==
                    ROOT .. "/"
                then
                    return
                        'getcustomasset("'
                        .. name
                        .. '")'
                end

                return
                    'getcustomasset("'
                    .. ROOT
                    .. "/"
                    .. name
                    .. '")'
            end
        )

    source =
        source:gsub(
            'getsynasset%s*%(%s*["\']([^"\']+)["\']%s*%)',
            function(name)

                if name:sub(1, #ROOT + 1) ==
                    ROOT .. "/"
                then
                    return
                        'getsynasset("'
                        .. name
                        .. '")'
                end

                return
                    'getsynasset("'
                    .. ROOT
                    .. "/"
                    .. name
                    .. '")'
            end
        )

    return source
end

--==============================================================
-- SANITIZA SCRIPT
--==============================================================

local function Sanitize(source)
    source =
        StripInternalDownloads(
            source
        )

    source =
        PatchAssets(
            source
        )

    return source
end

--==============================================================
-- CARREGAR MANIFESTO
--==============================================================

local function SaveManifest()

    local out = {
        "return {"
    }

    for url, info in pairs(CACHE) do

        local u =
            tostring(url)
            :gsub("\\", "\\\\")
            :gsub('"', '\\"')

        local p =
            tostring(info.path)
            :gsub("\\", "\\\\")
            :gsub('"', '\\"')

        table.insert(
            out,
            string.format(
                '["%s"]={path="%s",kind="%s"},',
                u,
                p,
                info.kind
            )
        )
    end

    table.insert(
        out,
        "}"
    )

    Write(
        MANIFEST,
        table.concat(
            out,
            "\n"
        )
    )
end

local function LoadManifest()

    if not IsFile(MANIFEST) then
        return false
    end

    local src = Read(MANIFEST)

    if not src then
        return false
    end

    local fn = loadstring(src)

    if not fn then
        return false
    end

    local ok, data = pcall(fn)

    if
        not ok
        or type(data) ~= "table"
    then
        return false
    end

    CACHE = data

    return true
end

--==============================================================
-- GERAR AMBIENTE OFFLINE
--==============================================================

local function BuildOfflineEnvironment()

    local sources = {}

    for url, info in pairs(CACHE) do

        if
            info.kind == "script"
            and IsFile(info.path)
        then

            local src =
                Read(info.path)

            if src then

                src =
                    Sanitize(
                        src
                    )

                sources[url] = src

                -- salva sanitizado
                Write(
                    info.path,
                    src
                )
            end
        end
    end

    return sources
end

--==============================================================
-- EXECUTAR SCRIPT LOCAL
--==============================================================

local function ExecuteCached(url)

    local info =
        CACHE[url]

    if not info then
        error(
            "Não existe no cache:\n"
            .. tostring(url)
        )
    end

    local rootSource =
        Read(info.path)

    if not rootSource then
        error(
            "Arquivo ausente:\n"
            .. tostring(info.path)
        )
    end

    rootSource =
        Sanitize(
            rootSource
        )

    --==========================================================
    -- TODAS AS DEPENDÊNCIAS SÃO COLOCADAS EM MEMÓRIA
    --==========================================================

    local Sources =
        BuildOfflineEnvironment()

    --==========================================================
    -- HTTP OFFLINE
    --
    -- game:HttpGet(...) dos scripts já foi trocado por
    -- __OFFLINE_GET(...)
    --==========================================================

    local prefix = [[

local __OFFLINE_SOURCES = ...;

local function __OFFLINE_GET(url)
    local data = __OFFLINE_SOURCES[url]

    if not data then
        error(
            "[Offline Movesets] Dependência não encontrada: "
            .. tostring(url)
        )
    end

    return data
end

]]

    --==========================================================
    -- TROCA DE HttpGet
    --==========================================================

    rootSource =
        rootSource:gsub(
            "game%s*:%s*HttpGet%s*%(",
            "__OFFLINE_GET("
        )

    rootSource =
        rootSource:gsub(
            "game%s*%.%s*HttpGet%s*%(%s*game%s*,",
            "__OFFLINE_GET("
        )

    --==========================================================
    -- COMPILA
    --==========================================================

    local complete =
        prefix
        .. rootSource

    local fn, err =
        loadstring(
            complete
        )

    if not fn then

        error(
            "Erro compilando "
            .. tostring(url)
            .. "\n\n"
            .. tostring(err)
        )
    end

    --==========================================================
    -- PASSA CACHE COMO ARGUMENTO
    --==========================================================

    local ok, result =
        pcall(
            fn,
            Sources
        )

    if not ok then
        error(
            "Erro executando "
            .. tostring(url)
            .. "\n\n"
            .. tostring(result)
        )
    end

    return result
end

--==============================================================
-- INSTALAR MOVESET
--==============================================================

local function InstallMoveset(name)

    if Installing then
        return false
    end

    local list =
        SOURCES[name]

    if not list then
        return false
    end

    Installing = true

    Notify(
        "Instalação",
        "Baixando " .. name .. "..."
    )

    local ok, err =
        pcall(
            function()

                for _, url in ipairs(list) do
                    InstallUrl(
                        url,
                        {}
                    )
                end

                -- Descobre dependências novas
                -- repetidamente.
                local changed = true

                while changed do

                    changed = false

                    local copy = {}

                    for url, info in pairs(CACHE) do
                        copy[url] = info
                    end

                    for url, info in pairs(copy) do

                        if
                            info.kind ==
                                "script"
                            and IsFile(info.path)
                        then

                            local src =
                                Read(info.path)

                            if src then

                                for _, dep in ipairs(
                                    ExtractUrls(src)
                                ) do

                                    if
                                        not CACHE[dep]
                                    then

                                        InstallUrl(
                                            dep,
                                            {}
                                        )

                                        changed = true
                                    end

                                end
                            end
                        end
                    end
                end

                SaveManifest()

                -- Sanitiza tudo uma vez
                BuildOfflineEnvironment()

            end
        )

    Installing = false

    if not ok then

        warn(
            "[Movesets]",
            err
        )

        Notify(
            "Erro",
            tostring(err),
            8
        )

        return false
    end

    Notify(
        "Pronto",
        name .. " instalado."
    )

    return true
end

--==============================================================
-- RODAR
--==============================================================

local function RunMoveset(name)

    local roots =
        SOURCES[name]

    if not roots then
        return
    end

    local missing = false

    for _, root in ipairs(roots) do

        if not CACHE[root] then
            missing = true
            break
        end

        if not IsFile(
            CACHE[root].path
        ) then
            missing = true
            break
        end

    end

    if missing then

        if not InstallMoveset(name) then
            return
        end
    end

    task.spawn(
        function()

            for _, root in ipairs(roots) do

                local ok, err =
                    pcall(
                        function()
                            ExecuteCached(root)
                        end
                    )

                if not ok then

                    warn(
                        "[Movesets Offline] "
                        .. name
                        .. "\n"
                        .. tostring(err)
                    )

                    Notify(
                        "Erro " .. name,
                        tostring(err),
                        8
                    )

                    return
                end

            end

            Notify(
                "Sucesso",
                name
                .. " executado pelo cache."
            )
        end
    )
end

--==============================================================
-- RESET
--==============================================================

local function ResetCache()

    if type(listfiles) ~= "function"
        or type(delfile) ~= "function"
    then
        Notify(
            "Erro",
            "Seu executor não suporta listfiles/delfile."
        )
        return
    end

    local files =
        listfiles(ROOT)

    for _, file in ipairs(files) do
        pcall(
            delfile,
            file
        )
    end

    CACHE = {}

    Notify(
        "Cache",
        "Cache apagado."
    )
end

--==============================================================
-- UI
--==============================================================

local old =
    PlayerGui:FindFirstChild(
        "OfflineMovesets"
    )

if old then
    old:Destroy()
end

local Gui =
    Instance.new("ScreenGui")

Gui.Name =
    "OfflineMovesets"

Gui.ResetOnSpawn = false
Gui.Parent =
    PlayerGui

local Main =
    Instance.new("Frame")

Main.Size =
    UDim2.fromOffset(
        275,
        410
    )

Main.Position =
    UDim2.new(
        0.5,
        -137,
        0.5,
        -205
    )

Main.BackgroundColor3 =
    Color3.fromRGB(
        20,
        20,
        25
    )

Main.BorderSizePixel = 0
Main.Parent = Gui

Instance.new(
    "UICorner",
    Main
).CornerRadius =
    UDim.new(
        0,
        14
    )

local Header =
    Instance.new("Frame")

Header.Size =
    UDim2.new(
        1,
        0,
        0,
        48
    )

Header.BackgroundColor3 =
    Color3.fromRGB(
        28,
        28,
        35
    )

Header.BorderSizePixel = 0
Header.Parent = Main

Instance.new(
    "UICorner",
    Header
).CornerRadius =
    UDim.new(
        0,
        14
    )

local Title =
    Instance.new("TextLabel")

Title.Size =
    UDim2.new(
        1,
        -20,
        1,
        0
    )

Title.Position =
    UDim2.fromOffset(
        12,
        0
    )

Title.BackgroundTransparency = 1
Title.Text =
    "OFFLINE MOVESETS"

Title.TextColor3 =
    Color3.new(
        1,
        1,
        1
    )

Title.TextSize = 15
Title.Font =
    Enum.Font.GothamBold

Title.TextXAlignment =
    Enum.TextXAlignment.Left

Title.Parent =
    Header

local Status =
    Instance.new("TextLabel")

Status.Size =
    UDim2.new(
        1,
        -20,
        0,
        38
    )

Status.Position =
    UDim2.fromOffset(
        10,
        55
    )

Status.BackgroundTransparency = 1

Status.Text =
    "Preparando..."

Status.TextColor3 =
    Color3.fromRGB(
        160,
        160,
        170
    )

Status.TextSize = 11
Status.Font =
    Enum.Font.Gotham

Status.TextWrapped = true
Status.Parent = Main

local function Button(text, y)

    local b =
        Instance.new("TextButton")

    b.Size =
        UDim2.new(
            1,
            -20,
            0,
            45
        )

    b.Position =
        UDim2.fromOffset(
            10,
            y
        )

    b.BackgroundColor3 =
        Color3.fromRGB(
            38,
            38,
            48
        )

    b.BorderSizePixel = 0

    b.Text =
        text

    b.TextColor3 =
        Color3.new(
            1,
            1,
            1
        )

    b.TextSize = 14
    b.Font =
        Enum.Font.GothamBold

    b.AutoButtonColor = false
    b.Parent = Main

    Instance.new(
        "UICorner",
        b
    ).CornerRadius =
        UDim.new(
            0,
            10
        )

    return b
end

local InstallAll =
    Button(
        "⚡ INSTALAR / ATUALIZAR",
        100
    )

local Jun =
    Button(
        "1 • JUN",
        153
    )

local Sukuna =
    Button(
        "2 • SUKUNA",
        206
    )

local Garou =
    Button(
        "3 • GAROU CÓSMICO",
        259
    )

local Gojo =
    Button(
        "4 • GOJO",
        312
    )

local Reset =
    Button(
        "🗑 APAGAR CACHE",
        365
    )

--==============================================================
-- BUTTON EVENTS
--==============================================================

InstallAll.MouseButton1Click:Connect(
    function()

        Status.Text =
            "Instalando os 4 movesets..."

        task.spawn(
            function()

                for _, name in ipairs({
                    "JUN",
                    "SUKUNA",
                    "GAROU",
                    "GOJO"
                }) do

                    InstallMoveset(
                        name
                    )

                    task.wait(0.25)
                end

                Status.Text =
                    "Tudo instalado em /Movesets"

            end
        )

    end
)

Jun.MouseButton1Click:Connect(
    function()

        Status.Text =
            "Carregando JUN..."

        RunMoveset(
            "JUN"
        )

    end
)

Sukuna.MouseButton1Click:Connect(
    function()

        Status.Text =
            "Carregando SUKUNA..."

        RunMoveset(
            "SUKUNA"
        )

    end
)

Garou.MouseButton1Click:Connect(
    function()

        Status.Text =
            "Carregando GAROU..."

        RunMoveset(
            "GAROU"
        )

    end
)

Gojo.MouseButton1Click:Connect(
    function()

        Status.Text =
            "Carregando GOJO..."

        RunMoveset(
            "GOJO"
        )

    end
)

Reset.MouseButton1Click:Connect(
    function()

        ResetCache()

        Status.Text =
            "Cache apagado. Instale novamente."

    end
)

--==============================================================
-- DRAG
--==============================================================

local dragging = false
local dragStart
local startPos
local dragInput

Header.InputBegan:Connect(
    function(input)

        if
            input.UserInputType ==
                Enum.UserInputType.MouseButton1
            or
            input.UserInputType ==
                Enum.UserInputType.Touch
        then

            dragging = true
            dragStart = input.Position
            startPos = Main.Position

            input.Changed:Connect(
                function()

                    if
                        input.UserInputState ==
                            Enum.UserInputState.End
                    then
                        dragging = false
                    end

                end
            )
        end
    end
)

Header.InputChanged:Connect(
    function(input)

        if
            input.UserInputType ==
                Enum.UserInputType.MouseMovement
            or
            input.UserInputType ==
                Enum.UserInputType.Touch
        then

            dragInput = input

        end

    end
)

UserInputService.InputChanged:Connect(
    function(input)

        if
            input == dragInput
            and dragging
        then

            local delta =
                input.Position -
                dragStart

            Main.Position =
                UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )

        end
    end
)

--==============================================================
-- START
--==============================================================

if LoadManifest() then

    Status.Text =
        "Cache encontrado.\n"
        .. "Não precisa baixar novamente."

    Notify(
        "Offline",
        "Cache encontrado."
    )

else

    Status.Text =
        "Cache inexistente.\n"
        .. "Clique em INSTALAR / ATUALIZAR."

    Notify(
        "Primeira execução",
        "Faça a instalação uma vez."
    )

end