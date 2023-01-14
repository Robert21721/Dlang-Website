import vibe.d;
import vibe.vibe;
import virus_total;
import db_conn;
import vibe.http.status;

import std.process;
import std.stdio;
import std.file;
import std.string;
import std.algorithm;

DBConnection dbClient;
VirusTotalAPI virusTotalAPI;
string currentFileMessage;
string currentURLMessage;
string URLSecurityLevel;
bool ok = false;

void main()
{
    dbClient = DBConnection("root", "example", "mongo", "27017", "testing");
    virusTotalAPI = new VirusTotalAPI(dbClient);

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["0.0.0.0"];
    settings.sessionStore = new MemorySessionStore;

    auto router = new URLRouter;

	
    router.get("/", &start);
    router.get("/login", &login);
    router.get("/register", &register);
    router.get("/error", &error);
    router.get("/test_file", &test_file);
    router.get("/file_response", &file_response);
    router.get("/test_URL", &test_URL);
    router.get("/URL_response", &URL_response);

    router.get("/home", &home);
    router.get("/home/user_files", &user_files);
    router.get("/home/user_URLs", &user_URLs);

    router.get("/home/test_file_auth", &test_file_auth);
    router.get("/home/test_URL_auth", &test_URL_auth);
    router.get("/home/file_response", &file_response_auth);
    router.get("/home/URL_response", &URL_response_auth);

    router.post("/post/login", &logUser);
    router.post("/post/register", &authUser);
    router.post("/post/logout", &logout);

    router.post("/post/input_file", &input_file);
    router.post("/post/input_file_auth", &input_file_auth);
    router.post("/post/input_URL", &input_URL);
    router.post("/post/input_URL_auth", &input_URL_auth);

    auto listener = listenHTTP(settings, router);

   scope (exit)
    {
        listener.stopListening();
    }

    writeln(router.getAllRoutes());
    runApplication();
}

void start(HTTPServerRequest req, HTTPServerResponse res)
{
    if (ok) {
        render!("home.dt")(res);
    } else {
    render!("landing.dt")(res);
    }
}

void login(HTTPServerRequest req, HTTPServerResponse res)
{
    if (ok) {
        render!("home.dt")(res);
    } else {
    render!("login.dt")(res);
    }
}

void register(HTTPServerRequest req, HTTPServerResponse res)
{
    if (ok) {
        render!("home.dt")(res);
    } else {
    render!("register.dt")(res);
    }
}

void home(HTTPServerRequest req, HTTPServerResponse res)
{
    render!("home.dt")(res);
}

void error(HTTPServerRequest req, HTTPServerResponse res)
{
    render!("error.dt")(res);
}

void test_file(HTTPServerRequest req, HTTPServerResponse res)
{
    render!("test_file.dt")(res);
}

void test_file_auth(HTTPServerRequest req, HTTPServerResponse res)
{
    render!("test_file_auth.dt")(res);
}

void test_URL(HTTPServerRequest req, HTTPServerResponse res)
{
    render!("test_URL.dt")(res);
}

void test_URL_auth(HTTPServerRequest req, HTTPServerResponse res)
{
    render!("test_URL_auth.dt")(res);
}

void user_files(HTTPServerRequest req, HTTPServerResponse res)
{
    auto email = req.session.get("email", "default@gmail.com").to!string();
    auto files = virusTotalAPI.getUserFiles(email);

    logInfo(files.toString());

    logInfo("user curent: "~email);

    auto data = "<html><head>\n<title>Tell me!</title>\n</head><body>\n<article>\n<h1>My Files</h1><br></br>";

    for (int i = 0; i < files.length; i++) {
        auto file = files[i];

        string fileName = file["fileName"].get!string;
        string securityLevel = file["securityLevel"].get!string;
        auto binData = file["binData"];
        ubyte[] fileContent;

        for (int j = 0; j < binData.length; j++) {
            fileContent ~= binData[j].get!ubyte;
        }
        string text = cast(string) fileContent;

        
        data~="\n<h2>fileName: "~fileName~"</h2>";
        data~="<p>securityLevel: "~securityLevel~"</p>\n";
        data~=  "<details>
                <summary>See File content</summary>";

        data~="<p><pre>"~text~"</pre></p>";
        data~="</details>";

        // logInfo(fileName);
        // logInfo(securityLevel);
        // logInfo(text);
    }

    data ~= "\n<style>
        body {
            background: linear-gradient(rgba(0,0,0,0.5),rgba(0, 0,0,0.5)), url(https://wallpaperaccess.com/full/516010.jpg);
            min-block-size: 100%;
            min-inline-size: 100%;
            box-sizing: border-box;
            display: grid;
            place-content: up;
            font-family: system-ui;
            font-size: 2vmin;
        }

        article {
            background: linear-gradient(
                to right, 
                hsl(98 100% 62%), 
                hsl(204 100% 59%)
            );
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            text-align: left;
        }

        h1 {
            text-align: center;
            font-size: 10vmin;
            line-height: 1.1;
        }

        h1, p, body {
            margin: 0;
        }

        p {
            font-family: \"Dank Mono\", ui-monospace, monospace;
        }

        html {
            block-size: 100%;
            inline-size: 100%;
        }
        </style>\n";
    data ~= "</article>\n</body></html>";

    // logInfo(data);


    res.writeBody(data, "text/html; charset=UTF-8");
    render!("user_files.dt")(res);
    
}

void user_URLs(HTTPServerRequest req, HTTPServerResponse res)
{
    auto email = req.session.get("email", "default@gmail.com").to!string();
    auto URLs = virusTotalAPI.getUserUrls(email);

    logInfo("user curent: "~email);

    auto data = "<html><head>\n<title>Tell me!</title>\n</head><body>\n<article>\n<h1>My URLs</h1><br></br>";

    for (int i = 0; i < URLs.length; i++) {
        auto URL = URLs[i];

        string URL_name = URL["addr"].get!string;
        string securityLevel = URL["securityLevel"].get!string;

        
        data~="\n<h2>URL: "~URL_name~"</h2>";
        data~="<p>securityLevel: "~securityLevel~"</p>\n";

        // logInfo(fileName);
        // logInfo(securityLevel);
        // logInfo(text);
    }

    data ~= "\n<style>
        body {
            background: linear-gradient(rgba(0,0,0,0.5),rgba(0, 0,0,0.5)), url(https://wallpaperaccess.com/full/516010.jpg);
            min-block-size: 100%;
            min-inline-size: 100%;
            box-sizing: border-box;
            display: grid;
            place-content: up;
            font-family: system-ui;
            font-size: 2vmin;
        }

        article {
            background: linear-gradient(
                to right, 
                hsl(98 100% 62%), 
                hsl(204 100% 59%)
            );
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            text-align: left;
        }

        h1 {
            text-align: center;
            font-size: 10vmin;
            line-height: 1.1;
        }

        h1, p, body {
            margin: 0;
        }

        p {
            font-family: \"Dank Mono\", ui-monospace, monospace;
        }

        html {
            block-size: 100%;
            inline-size: 100%;
        }
        </style>\n";
    data ~= "</article>\n</body></html>";

    // logInfo(data);


    res.writeBody(data, "text/html; charset=UTF-8");
    render!("user_URLs.dt")(res);
    
}


void logUser(HTTPServerRequest req, HTTPServerResponse res)
{
    auto email = req.json["userEmail"].to!string();
    auto password = req.json["password"].to!string();

    logInfo(email);
    logInfo(password);

    try {
        virusTotalAPI.authUser(email, password);

    } catch(Exception e) {
        logInfo("EXCEPTION");
        res.redirect("/error");
    }

    ok = true;
    auto session = res.startSession();
    session.set("email", email);
    res.redirect("/home"); 
}

void authUser(HTTPServerRequest req, HTTPServerResponse res)
{
    auto name = req.json["name"].to!string();
    auto username = req.json["username"].to!string();
    auto email = req.json["userEmail"].to!string();
    auto password = req.json["password"].to!string();

    logInfo(name);
    logInfo(username);
    logInfo(email);
    logInfo(password);

    try {
        virusTotalAPI.addUser(email, username, password, name);

    } catch(Exception e) {
        logInfo("EXCEPTION");
        res.redirect("/error");
    }

    ok = true;
    auto session = res.startSession();
	session.set("email", email);
    res.redirect("/home"); 
}

void logout(HTTPServerRequest req, HTTPServerResponse res)
{   
    ok = false;
    res.terminateSession();
    logInfo("am iesiiiiiiit");
    res.redirect("/"); 
}

void input_file(HTTPServerRequest req, HTTPServerResponse res)
{
    auto file = "file" in req.files;

    try {
        moveFile(file.tempPath, Path("./") ~ file.filename);
        logInfo("Uploaded successfully!");

    } catch(Exception e) {
        logInfo("Exception thrown, trying copy");
        copyFile(file.tempPath, Path("./") ~ file.filename);
    }
    
    currentFileMessage = fileMessage(file.filename.to!string());

    try {
        removeFile(Path("./") ~ file.filename);
        logInfo("file removed");

    } catch(Exception e) {
        logInfo("file does not exist");
    }
    
    res.redirect("/file_response");
}


void input_file_auth(HTTPServerRequest req, HTTPServerResponse res)
{
    auto file = "file" in req.files;

    try {
        moveFile(file.tempPath, Path("./") ~ file.filename);
        logInfo("Uploaded successfully!");

    } catch(Exception e) {
        logInfo("Exception thrown, trying copy");
        copyFile(file.tempPath, Path("./") ~ file.filename);
    }

    currentFileMessage = fileMessage(file.filename.to!string());

    auto binData = cast(immutable ubyte[]) read(file.filename.to!string());
    // logInfo(cast(string) binData);

    string email = req.session.get("email", "default@gmail.com").to!string();
    // logInfo("file auth current user "~email);

    auto json = virusTotalAPI.addFile(email, binData, file.filename.to!string(), "high");
    // logInfo("am introdus fisierul cu urmatoarele caracterisitci: " ~ json.toString());

    string message = json.toString();
    if (canFind(message, "already present in the database")) {
        currentFileMessage = "FILE ALREADY EXISTS";
    }


    try {
        removeFile(Path("./") ~ file.filename);
        logInfo("file removed");

    } catch(Exception e) {
        logInfo("file does not exist");
    }
    
    res.redirect("/home/file_response");
}

void input_URL(HTTPServerRequest req, HTTPServerResponse res)
{
    string URL = req.form.get("URL");

    currentURLMessage = URLMessage(URL);
    // AICI VA FI DOAR VERIFICATA

    logInfo(URL);
    
    res.redirect("/URL_response");
}

void input_URL_auth(HTTPServerRequest req, HTTPServerResponse res)
{
    string URL = req.form.get("URL");

    currentURLMessage = URLMessage(URL);
    // AICI VA FI DOAR VERIFICATA
    string email = req.session.get("email", "default@gmail.com").to!string();
    virusTotalAPI.addUrl(email, URL, URLSecurityLevel);

    logInfo(URL);
    
    res.redirect("/home/URL_response");
}

string fileMessage(string fileName)
{
    if (fileName.endsWith(".d")) {
        return "NO MALWARE, NO DOCUMENTATION";
    } else if (fileName.endsWith(".c")) {
        return "NO VIRUSES, ONLY BUGS";
    } else if (fileName.endsWith(".rs")) {
        return "I AM NOT SURE, FILE DID NOT COMPILE";
    } else {
        return "YOU ARE NOT A PROGRAMMER, SO YOU ARE (MENTALLY) SAFE";
    }
}

string URLMessage(string URL)
{
    // nu i place asta
    if (canFind(URL, "https")) {
        URLSecurityLevel = "high";
        return "SECURE";
    } else {
        URLSecurityLevel = "low";
        return "NOT SURE";
    }
}

void URL_response(HTTPServerRequest req, HTTPServerResponse res)
{   
    string str = currentURLMessage;
    render!("response.dt", str)(res);
}

void file_response(HTTPServerRequest req, HTTPServerResponse res)
{
    string str = currentFileMessage;
    render!("response.dt", str)(res);
}


void URL_response_auth(HTTPServerRequest req, HTTPServerResponse res)
{
    string str = currentURLMessage;
    render!("response_auth.dt", str)(res);
}

void file_response_auth(HTTPServerRequest req, HTTPServerResponse res)
{
    string str = currentFileMessage;
    render!("response_auth.dt", str)(res);
}