import vibe.d;
import vibe.vibe;
import virus_total;
import db_conn;
import vibe.http.status;

import std.stdio;

void main()
{

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["0.0.0.0"];
    settings.sessionStore = new MemorySessionStore;

    auto router = new URLRouter;
    // router.registerWebInterface(virusTotalAPI);
	
    router.get("/", &start);
    router.get("/login", &login);
    router.get("/register", &register);
    router.get("/home", &home);
    router.get("/error", &error);

    router.post("/post/login", &logUser);
    router.post("/post/register", &authUser);


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
    render!("home.dt")(res);
}

void error(HTTPServerRequest req, HTTPServerResponse res)
{
    render!("error.dt")(res);
}

void logUser(HTTPServerRequest req, HTTPServerResponse res)
{
    auto dbClient = DBConnection("root", "example", "mongo", "27017", "testing");
    auto virusTotalAPI = new VirusTotalAPI(dbClient);

    auto email = req.json["userEmail"].to!string();
    auto password = req.json["password"].to!string();

    logInfo(email);
    logInfo(password);

    try
    {
        virusTotalAPI.authUser(email, password);
    }
    catch(HTTPStatusException e)
    {
        logInfo("EXCEPTION");
        res.redirect("/error");
    }

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

    try
    {
        virusTotalAPI.addUser(email, username, password, name);
    }
    catch(HTTPStatusException e)
    {
        logInfo("EXCEPTION");
        res.redirect("/error");
    }

    res.redirect("/home"); 

    
}