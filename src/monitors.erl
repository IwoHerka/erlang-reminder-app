-module(monitors).
-compile(export_all).
-define(TIMEOUT, 5000).

worker() ->
    receive
        do_work ->
            io:format("~p is working...~n", [self()]),
            worker()
    after ?TIMEOUT ->
            io:format("~p has no work, exits.~n", [self()]),
            exit(no_activity)
    end.

parent() ->
    Pid = spawn(monitors, worker, []),
    register(worker, Pid),
    Ref = erlang:monitor(process, Pid),
    io:format("Parent ~p has a worker ~p~n", [self(), Pid]),
    ?MODULE ! {new_worker, Pid},
    receive
        {'DOWN', Ref, process, Pid, Reason} ->
            io:format("Worker is down: ~p ~p~n", [Pid, Reason]),
            parent()
    end.

loop() ->
    receive
        {new_worker, Pid} ->
            timer:sleep(?TIMEOUT - 2000),
            Pid ! do_work,
            loop()
    end.

start() ->
    Pid = spawn(monitors, loop, []),
    register(?MODULE, Pid),

    ParentPid = spawn(monitors, parent, []),
    register(parent, ParentPid),

    Ref = erlang:monitor(process, Pid),

    timer:sleep(?TIMEOUT * 2),
    exit(whereis(worker), finished),
    exit(whereis(parent), finished),
    exit(whereis(?MODULE), finished),

    ok.
