local inspect = require('inspect');

local dial = function (context, extension)
    app.noop("context: " .. context .. ", extension: " .. extension);

    local q = {
        w1 = channel["CDR(linkedid)"]:get();
        w2 = channel["CDR(uniqueid)"]:get();
    }

    app.noop('q: '..inspect(q));

    app.dial('SIP/' .. extension, 10);
    
    --app.dial('Local/' .. extension .. '@internal/n',10);

    local dialstatus = channel["DIALSTATUS"]:get();
    app.noop('dialstatus: '..dialstatus);
    app.set("CHANNEL(language)=ru");

    --app.sendtext('hello!!!!')

    local q = {
        w1 = channel["CDR(linkedid)"]:get();
        w2 = channel["CDR(uniqueid)"]:get();
    }

    app.noop('q: '..inspect(q));

    if dialstatus == 'BUSY' then
        app.playback("followme/sorry");        
    elseif dialstatus == 'CHANUNAVAIL' then 
        app.playback("followme/sorry");
    end;



    app.hangup();
end;

local ivr = function (context, extension)        
    app.read("IVR_CHOOSE", "/var/menu/demo", 1, nil, 2, 3);
    local choose = channel["IVR_CHOOSE"]:get();

    if choose == '1' then
        app.queue('1234');
    elseif choose == '2' then
        dial('internal', '101');
    else
        app.hangup();
    end;
end;

local couchdb_ivr = function (context, extension)
    app.noop('couchdb ivrs');
    --[[

        local server = require "luchia.core.server"
        -- Build a new server object.
        local srv = server:new()
        -- Make a request.
        local response = srv:request({
            path = "/",
        })
        
        app.noop('resp:'..inspect(response));
    ]]


    local database = require "luchia.database"
    local config = {
      connection = {
        protocol = "http",
        host = "192.168.1.23",
        port = "5984",
        user = "admin",
        password = "password",
      },
    };

    local db = database:new(config);

    local info = db:list();
    app.noop(inspect(info));

    local responsedata, responsecode, headers, status_code = db:create("btrn")
    app.noop(inspect({responsedata, responsecode, headers, status_code}));

    local document = require "luchia.document"
    local doc = document:new("ivrs", config)
    
    local query_parameters = { 
        include_docs = "true", 
        limit = "100" 
    };
    
    local response = doc:list(query_parameters);
    app.noop(inspect(response));

    local doc3 = doc:retrieve('_design/default_ivr/_view/new-view', query_parameters);
    if doc3 then
        app.noop(inspect(doc3.rows[1].doc.sound));
    end;

    query_parameters = {
        include_docs = "true",
        limit = "100",
        keys = '["hello"]'
    }

    local doc4 = doc:retrieve('_design/custom_ivr/_view/custom_by_sound', query_parameters);
    app.noop(inspect(doc4));

    app.playback('beep')
    app.hangup();
end;

extensions = {
    ["internal"] = {

        ["*12"] = function ()
            app.sayunixtime();
        end;

        ["_1XX"] = dial;

        ["200"] = ivr;

        ["201"] = couchdb_ivr;

        ["_XXXXXXXXXXX"] = function(context, extension)
            app.dial('PJSIP/'..extension..'@sipnet.ru');
        end;

        ["h"] = function()
            local dialstatus = channel["DIALSTATUS"]:get();
            app.noop('DIALSTATUS: '..tostring(dialstatus));

            local q = {
                w1 = channel["CDR(linkedid)"]:get();
                w2 = channel["CDR(uniqueid)"]:get();
            }

            app.noop('q: '..inspect(q));

            app.noop('hangup!')
        end;
    };
};

hints = {};