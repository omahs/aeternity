%%%=============================================================================
%%% @copyright (C) 2018, Aeternity Anstalt
%%% @doc
%%%    ADT for keeping the state of State Channels
%%% @end
%%%=============================================================================
-module(aesc_state_tree).

%% API
-export([commit_to_db/1,
         delete/2,
         empty/0,
         empty_with_backend/0,
         enter/2,
         get/2,
         lookup/2,
         mtree_iterator/1,
         new_with_backend/1,
         new_with_dirty_backend/1,
         root_hash/1]).

-export([ from_binary_without_backend/1
        , to_binary_without_backend/1
        , from_db_format/1
        ]).

%%%===================================================================
%%% Types
%%%===================================================================

-type channel() :: aesc_channels:channel().

-type chkey() :: aesc_channels:pubkey().
-type chvalue() :: aesc_channels:serialized().

-opaque tree() :: aeu_mtrees:mtree(chkey(), chvalue()).

-export_type([tree/0]).

-define(VSN, 1).
%%%===================================================================
%%% API
%%%===================================================================

-spec commit_to_db(tree()) -> tree().
commit_to_db(Tree) ->
    aeu_mtrees:commit_to_db(Tree).

-spec delete(aesc_channels:pubkey(), tree()) -> tree().
delete(PubKey, Tree) ->
    aeu_mtrees:delete(PubKey, Tree).

-spec empty() -> tree().
empty() ->
    aeu_mtrees:empty().

-spec empty_with_backend() -> tree().
empty_with_backend() ->
    aeu_mtrees:empty_with_backend(aec_db_backends:channels_backend()).

-spec from_db_format(tree()) -> tree().
from_db_format(Tree) ->
    aeu_mtrees:from_db_format(Tree).

-spec new_with_backend(aeu_mtrees:root_hash() | 'empty') -> tree().
new_with_backend(Hash) ->
    aeu_mtrees:new_with_backend(Hash, aec_db_backends:channels_backend()).

-spec new_with_dirty_backend(aeu_mtrees:root_hash() | 'empty') -> tree().
new_with_dirty_backend(Hash) ->
    aeu_mtrees:new_with_backend(Hash, aec_db_backends:dirty_channels_backend()).

-spec enter(channel(), tree()) -> tree().
enter(Channel, Tree) ->
    PubKey     = aesc_channels:pubkey(Channel),
    Serialized = aesc_channels:serialize(Channel),
    aeu_mtrees:enter(PubKey, Serialized, Tree).

-spec get(chkey(), tree()) -> aesc_channels:channel().
get(Id, Tree) ->
    aesc_channels:deserialize(Id, aeu_mtrees:get(Id, Tree)).

-spec lookup(chkey(), tree()) -> {value, channel()} | none.
lookup(PubKey, Tree) ->
    case aeu_mtrees:lookup(PubKey, Tree) of
        {value, Val} -> {value, aesc_channels:deserialize(PubKey, Val)};
        none         -> none
    end.

-spec root_hash(tree()) -> {ok, aeu_mtrees:root_hash()} | {error, empty}.
root_hash(Tree) ->
    aeu_mtrees:root_hash(Tree).

-spec to_binary_without_backend(tree()) -> binary().
to_binary_without_backend(Tree) ->
    Bin = aeu_mtrees:serialize(Tree),
    aeser_chain_objects:serialize(
        channels_mtree,
        ?VSN,
        serialization_template(?VSN),
        [{channels, Bin}]).

-spec from_binary_without_backend(binary()) -> tree().
from_binary_without_backend(Bin) ->
    [{channels, ChannelsBin}] =
        aeser_chain_objects:deserialize(channels_mtree, ?VSN,
                                             serialization_template(?VSN), Bin),
    aeu_mtrees:deserialize(ChannelsBin).

serialization_template(?VSN) ->
    [{channels, binary}].

-spec mtree_iterator(tree()) -> aeu_mtrees:iterator().
mtree_iterator(Tree) ->
    aeu_mtrees:iterator(Tree).
