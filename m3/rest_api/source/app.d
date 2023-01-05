import vibe.d;
import vibe.vibe;
import virus_total;
import db_conn;
import vibe.http.status;

import std.process;
import std.stdio;
import std.utf : byChar;
import std.file;

void main()
{
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
    auto dbClient = DBConnection("root", "example", "mongo", "27017", "testing");
    auto virusTotalAPI = new VirusTotalAPI(dbClient);

    auto email = req.session.get("email", "default@gmail.com").to!string();
    auto files = virusTotalAPI.getUserFiles(email);

    auto data = "<html><head>\n<title>Tell me!</title>\n</head><body>";

    for (int i = 0; i < files.length; i++) {
        auto file = files[i];
        string fileName = file["fileName"].get!string;
        string securityLevel = file["securityLevel"].get!string;

        data~="\n<h1>fileName: "~fileName~"</h1>\n";
        data~="<h2>securityLevel: "~securityLevel~"</h2>\n";

        logInfo(fileName);
        logInfo(securityLevel);
    }

    data ~= "</body></html>";

    logInfo(data);


    res.writeBody(data, "text/html; charset=UTF-8");
    render!("user_info.dt")(res);
    
}

void logUser(HTTPServerRequest req, HTTPServerResponse res)
{
    auto dbClient = DBConnection("root", "example", "mongo", "27017", "testing");
    auto virusTotalAPI = new VirusTotalAPI(dbClient);

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
    auto dbClient = DBConnection("root", "example", "mongo", "27017", "testing");
    auto virusTotalAPI = new VirusTotalAPI(dbClient);

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
    auto dbClient = DBConnection("root", "example", "mongo", "27017", "testing");
    auto virusTotalAPI = new VirusTotalAPI(dbClient);

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
    auto dbClient = DBConnection("root", "example", "mongo", "27017", "testing");
    auto virusTotalAPI = new VirusTotalAPI(dbClient);

    auto file = "file" in req.files;

    try {
        moveFile(file.tempPath, Path("./") ~ file.filename);
        logInfo("Uploaded successfully!");

    } catch(Exception e) {
        logInfo("Exception thrown, trying copy");
        copyFile(file.tempPath, Path("./") ~ file.filename);
    }


    auto binData = cast(immutable ubyte[]) read(file.filename.to!string());
    logInfo(cast(string) binData);

    string email = req.session.get("email", "default@gmail.com").to!string();
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
