import vibe.d;
import vibe.vibe;
import virus_total;
import db_conn;
import vibe.http.status;

import std.process;
import std.stdio;
import std.utf : byChar;
import std.file;

DBConnection dbClient;
VirusTotalAPI virusTotalAPI;

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
    router.get("/home/test_file", &test_file_auth);


    router.get("/home", &home);
    router.get("/home/user_info", &user_info);
    router.get("/home/test_file_auth", &test_file_auth);

    router.post("/post/login", &logUser);
    router.post("/post/register", &authUser);
    router.post("/post/logout", &logout);

    router.post("/post/input_file", &input_file);
    router.post("/post/input_file_auth", &input_file_auth);

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
    render!("landing.dt")(res);
}

void login(HTTPServerRequest req, HTTPServerResponse res)
{
    render!("login.dt")(res);
}

void register(HTTPServerRequest req, HTTPServerResponse res)
{
    render!("register.dt")(res);
}

void home(HTTPServerRequest req, HTTPServerResponse res)
{
    logInfo(req.session.get("email", "default@gmail.com").to!string());
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

void user_info(HTTPServerRequest req, HTTPServerResponse res)
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
    render!("user_info.dt")(res);
    
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

    auto session = res.startSession();
	session.set("email", email);
    res.redirect("/home"); 
}

void logout(HTTPServerRequest req, HTTPServerResponse res)
{
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
    
    // AICI VA FI DOAR VERIFICATA

    try {
        removeFile(Path("./") ~ file.filename);
        logInfo("file removed");

    } catch(Exception e) {
        logInfo("file does not exist");
    }
    
    res.redirect("/");
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


    auto binData = cast(immutable ubyte[]) read(file.filename.to!string());
    // logInfo(cast(string) binData);

    string email = req.session.get("email", "default@gmail.com").to!string();
    logInfo("file auth current user "~email);
    virusTotalAPI.addFile(email, binData, file.filename.to!string(), "high");

    // PLUS VERIFICARE

    try {
        removeFile(Path("./") ~ file.filename);
        logInfo("file removed");

    } catch(Exception e) {
        logInfo("file does not exist");
    }
    
    res.redirect("/home");
}
