-module(rw468).
-compile(export_all).


logger (Count) ->
    receive 
        %If any message received, output count + message
        Message -> io:fwrite("Logger Number [~w]: ~w",[Count,Message]), logger(Count) 
    end.

consumer (Buffer,Logger,Count) ->
    Buffer!{isEmptyQ,self()},
    receive 
        empty ->
            Logger!"Consumer received empty",
            receive 
                notEmpty -> 
                    Logger!"Consumer received notEmpty",
                    subConsumer(Buffer,Logger, Count)
            end;
        notEmpty -> 
            Logger!"Consumer received notEmpty",
            subConsumer(Buffer,Logger, Count)
    end.


subConsumer(Buffer, Logger,Count) ->
    Buffer!{getData,self()},
    receive
        {data,Msg} -> 
            Logger!"Consumer recieved data:" + Count + " = " + Msg,
            consumer(Buffer,Logger,Count+1)
    end.



buffer(MaxSize) ->buffer([], MaxSize, none, none).
buffer(BufferData, MaxSize, WaitingConsumer, WaitingProducer) ->

    receive 
        {isFullQ,P} when length(BufferData) < MaxSize ->
            WaitingProducer!notFull,
            receive 
                {data,Msg} -> buffer(BufferData++Msg, MaxSize, WaitingConsumer, WaitingProducer)
            end;
        {isFullQ,P} ->
            WaitingProducer!full,
            buffer(BufferData, MaxSize, WaitingConsumer, WaitingProducer);
    
        {isEmptyQ,C} when length(BufferData) > 0 -> 
            WaitingConsumer!notEmpty,
            receive 
                {getData,ConsumerID} -> [Head|Tail] = BufferData, ConsumerID!{data,Head}, buffer(Tail,MaxSize, WaitingConsumer, WaitingProducer)
            end;
        {isEmptyQ,C} ->
            WaitingConsumer!empty,
            buffer(BufferData, MaxSize, WaitingConsumer, WaitingProducer) 
            
    end.



