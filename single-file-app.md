# 🧩 Demystifying Single-File Apps in .NET 10 SDK Preview 6

## 📌 Introduction

.NET 10 SDK Preview 6 introduces a transformative feature for developers: **Single-File Apps** with direct execution via `dotnet run app.cs`. This capability streamlines development by allowing standalone `.cs` files to behave like full-fledged applications — no `.csproj`, no scaffolding, just code.

This article explores the **technical foundation**, **execution model**, and **real-world scenarios** where Single-File Apps shine. Whether you're scripting, prototyping, or building lightweight tools, this feature redefines how C# can be used.


## 🚀 What Are Single-File Apps?

Single-File Apps are C# programs written in a single `.cs` file that can be executed directly using:

```bash
dotnet run app.cs
```

They support **top-level statements**, **NuGet packages**, **SDK declarations**, and **MSBuild properties** — all embedded as **file-level directives**.

### 🔧 Key Capabilities

- No need for `.csproj` files
- Supports NuGet packages via `#:package`
- SDK selection via `#:sdk`
- MSBuild properties via `#:property`
- Native AOT publishing
- Project references via `#:project`
- Shebang support for Unix-like systems


## 🧠 Technical Background

### 🛠️ Execution Pipeline

When you run `dotnet run app.cs`, the CLI performs:

1. **Parsing**: Reads the `.cs` file and extracts directives.
2. **Virtual Project Generation**: Constructs an in-memory `.csproj` based on directives.
3. **Compilation**: Uses Roslyn to compile the file.
4. **Execution**: Runs the compiled binary in memory or publishes it as a native executable.

### 🧬 File-Level Directives

These directives mimic project file configurations:

- `#:package Newtonsoft.Json@13.0.3`  
  Adds NuGet package reference.

- `#:sdk Microsoft.NET.Sdk.Web`  
  Switches to ASP.NET Core SDK.

- `#:property LangVersion=preview`  
  Enables preview language features.

- `#:project ../MyLib/MyLib.csproj`  
  References external projects.

### 🧱 Native AOT Integration

Single-File Apps default to **Native AOT** when published:

```bash
dotnet publish app.cs
```

This compiles the app to a native binary, improving startup time and reducing memory footprint. You can disable AOT with:

```csharp
#:property PublishAot=false
```

### 📂 Runtime Path Access

Apps can access their source path via:

```csharp
AppContext.GetData("EntryPointFilePath")
AppContext.GetData("EntryPointFileDirectoryPath")
```

Or use `[CallerFilePath]` for compile-time resolution.


## 🔍 Why It Works: Design Philosophy

### 🧪 Minimalism Meets Power

The feature is inspired by scripting languages like Python and JavaScript. It lowers the barrier to entry while preserving the full power of C# and .NET.

### 🧰 MSBuild Compatibility

Directives are translated into MSBuild-compatible properties, ensuring seamless migration to full projects via:

```bash
dotnet project convert app.cs
```

### 🧵 Seamless Growth Path

Single-File Apps are not a separate dialect. They use the same compiler, runtime, and tooling — making them ideal for prototyping that scales.


## 🧪 Example Usage Scenarios

### 1. 🧾 CLI Utilities

Create quick automation scripts:

```csharp
#!/usr/bin/env dotnet run
Console.WriteLine("Disk usage: " + DriveInfo.GetDrives().Sum(d => d.TotalSize));
```

Make it executable:

```bash
chmod +x disk.cs
./disk.cs
```

### 2. 🧪 Prototyping with NuGet

```csharp
#:package Humanizer@2.14.1
using Humanizer;

Console.WriteLine("3 days ago".Humanize());
```

Run instantly:

```bash
dotnet run humanize.cs
```

### 3. 🌐 Minimal Web API

```csharp
#:sdk Microsoft.NET.Sdk.Web
#:package Microsoft.AspNetCore.OpenApi@10.0.0-preview.6

var builder = WebApplication.CreateBuilder();
builder.Services.AddOpenApi();
var app = builder.Build();

app.MapGet("/", () => "Hello, world!");
app.Run();
```

### 4. 🧪 Teaching & Learning

Perfect for educational environments — students can run code without setup:

```csharp
Console.WriteLine("Welcome to C# in one file!");
```

### 5. 🧩 Integration Testing

Use file-based apps to test libraries:

```csharp
#:project ../MyLib/MyLib.csproj
var result = MyLib.DoSomething();
Console.WriteLine(result);
```

### 6. 🧠 DevOps & CI/CD Scripts

Embed logic directly into build pipelines:

```csharp
#:package Octokit@0.50.0
using Octokit;

var client = new GitHubClient(new ProductHeaderValue("MyApp"));
var repo = await client.Repository.Get("dotnet", "runtime");
Console.WriteLine(repo.Description);
```


## ⚠️ Limitations & Considerations

- Not ideal for multi-file apps (yet)
- Limited debugging support in some IDEs
- Some APIs (e.g. `Assembly.Location`) behave differently
- Native AOT may restrict dynamic features


## 🧭 Migration Path

Convert to full project when needed:

```bash
dotnet project convert app.cs
```

This generates:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <PublishAot>true</PublishAot>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Humanizer" Version="2.14.1" />
  </ItemGroup>
</Project>
```


## 🧠 Final Thoughts

Single-File Apps in .NET 10 SDK Preview 6 are a leap forward in developer ergonomics. They combine the simplicity of scripting with the robustness of compiled applications. Whether you're a seasoned backend engineer or a curious learner, this feature empowers you to build faster, test smarter, and deploy leaner.


## 📦 Where Compiled Output Is Stored

### 🏃 When Using `dotnet run app.cs`
- The SDK creates a **temporary build folder** under your user profile:
  - **Windows**: `%TEMP%\.dotnet\script\`
  - **Linux/macOS**: `$HOME/.dotnet/script/`
- This folder contains:
  - A generated `.csproj`
  - NuGet package cache
  - Intermediate build artifacts
  - Final compiled DLL or EXE

You can inspect it by navigating to:
```bash
%TEMP%\.dotnet\script\  # Windows
$HOME/.dotnet/script/   # Linux/macOS
```


### 📤 When Using `dotnet publish app.cs`
- The output goes to:
  ```bash
  ./bin/<Configuration>/<TargetFramework>/<RuntimeIdentifier>/publish/
  ```
  Example:
  ```
  ./bin/Release/net10.0/win-x64/publish/
  ```

You can override this with:
```bash
dotnet publish app.cs --output ./dist
```


## 🧹 How to Check and Clear the Output

### 🔍 Check Output Contents
Use file explorer or terminal:
```bash
ls $HOME/.dotnet/script/         # macOS/Linux
dir %TEMP%\.dotnet\script\       # Windows
```

Or inspect published binaries:
```bash
ls ./bin/Release/net10.0/win-x64/publish/
```

### 🧼 Clear Temporary Build Artifacts
To clean up SDK-generated files:

#### ✅ Option 1: Manual Deletion
```bash
rm -rf $HOME/.dotnet/script/     # macOS/Linux
rd /s /q %TEMP%\.dotnet\script\  # Windows
```

#### ✅ Option 2: Use `dotnet clean`
If you're working inside a project:
```bash
dotnet clean
```


## 🧠 Bonus: Control Output Location

You can customize the output path in your `.csproj` (if converted to a project):

```xml
<PropertyGroup>
  <OutputPath>./dist/</OutputPath>
  <AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath>
</PropertyGroup>
```

This flattens the folder structure and puts your binary exactly where you want it.


You’ve got a few slick ways to check the `%TEMP%` environment variable on Windows, Iong — here’s the rundown:


## 🧭 Quick Ways to Check `%TEMP%`

### 🖥️ 1. **Using Command Prompt**
Open Command Prompt and type:
```cmd
echo %TEMP%
```
This will print the full path of your current user's temp folder — usually something like:
```
C:\Users\<YourUsername>\AppData\Local\Temp
```


### 🧰 2. **Using PowerShell**
Open PowerShell and run:
```powershell
$env:TEMP
```
Same result, just the PowerShell flavor.


### ⚙️ 3. **Via Environment Variables UI**
1. Press `Win + Pause/Break` → opens System Properties.
2. Click **Advanced system settings**.
3. Under the **Advanced** tab, click **Environment Variables**.
4. Look under **User variables** for `TEMP` and `TMP`.


### 🧪 4. **Using Run Dialog**
Press `Win + R`, type:
```
%TEMP%
```
Hit Enter — this opens the folder directly in File Explorer.

---


"The more I look into C#, the surer I feel about NodeJS."

"Everything is ephemeral."

「日日醉涼州，笙歌卒未休，感恩知有地，不上望京樓」
《紫釵記》

1. [The New Way to Write .NET Apps (and It's Awesome)](https://youtu.be/1Yv6rihgTM0)

2. [Download .NET 10.0](https://dotnet.microsoft.com/en-us/download/dotnet/10.0)

