-module(ext_tokenline_pp).

-export([open_file/3]).


open_file(FileName, Passes, Options) ->
    case ext_epp:open_file(FileName, Passes, Options) of
        {ok, State, Cont} ->
            {ok, State, scan_form(Cont)};
        Other ->
            Other
    end.


scan_form(Cont) ->
    fun (State) ->
            case Cont(State) of
                {{ok, Tokens}, State1, Cont1} ->
                    {{ok, transform_tokens(Tokens)}, State1, scan_form(Cont1)};
                {{eof, _}, _State1, eof} = EOF ->
                    EOF;
                {Other, State1, Cont1} ->
                    {Other, State1, scan_form(Cont1)}
            end
    end.


transform_tokens([]) ->
    [];
transform_tokens([{Type, Attrs}|T]) ->
    [{Type, attrs_line(Attrs)}|transform_tokens(T)];
transform_tokens([{Type, Attrs, Value}|T]) ->
    [{Type, attrs_line(Attrs), Value}|transform_tokens(T)].


attrs_line(Attrs) ->
    {line, L} = erl_scan:attributes_info(Attrs, line),
    L.

