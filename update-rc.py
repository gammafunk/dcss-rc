#!/usr/bin/env python3

"""
Using a single rc file, update a set of DCSS games (versions) on a set of
WebTiles servers over WebSockets. Default locations for rc files are ~/.crawlrc
and ~/.crawl/init.txt

"""

import argparse
import asyncio
import getpass
import json
import os
import os.path
import re
import sys
import time
import websockets
import zlib

@asyncio.coroutine
def connect(url):
    global messages

    print("Connecting to " + url)
    webs = yield from websockets.connect(url)
    print("Connected to " + url)
    messages.append({"msg" : "login",
                     "username" : username,
                     "password" : password})
    yield from handler(webs)

@asyncio.coroutine
def send_message(webs):
    global messages

    if not len(messages):
        return

    message = messages.pop(0)
    print("Sending message " + message["msg"])
    yield from webs.send(json.dumps(message))

def update_rcs(webs, message):
    global messages
    global found_games
    global rc_text

    game_pattern = r'<a href="#play-([^"]+)">([^>]+)</a>'
    for m in re.finditer(game_pattern, message["content"]):
        game_id = m.group(1)
        game_name = m.group(2)

        do_update = False
        for g in update_games:
            ## Need a better way to match this
            if re.search("DCSS.*" + g, game_name, flags=re.IGNORECASE):
                do_update = True
                found_games.append(g)
                break

        if do_update:
            data = {"msg" : "set_rc",
                    "game_id" : game_id,
                    "contents" : rc_text}
            messages.append(data)

    if len(found_games) != len(update_games):
        game_desc =  "None"
        if len(found_games):
            game_desc = ",".join(found_games)
        sys.exit("Error: Requested games: {0}; "
                 "Found games: {1}".format(args.games, game_desc))


@asyncio.coroutine
def handle_message(webs, message):
    global messages

    if message["msg"] == "ping":
        print("Received ping")
        response = {"msg" : "pong"}
        messages.append(response)
    elif message["msg"] == "login_success":
        print("Login successful")
    elif message["msg"] == "set_game_links":
        if "content" not in message:
            print("Invalid set_game_links message" + json.dumps(message))
            yield from webs.close()
        else:
            update_rcs(webs, message)
    elif message["msg"] == "login_fail":
        yield from webs.close()
        sys.exit("Login failed; shutting down")
        return

@asyncio.coroutine
def handler(webs):
    global messages
    global decomp
    global found_games

    while True:
        listener_task = asyncio.async(webs.recv())
        producer_task = asyncio.async(send_message(webs))

        done, pending = yield from asyncio.wait(
            [listener_task, producer_task],
            return_when=asyncio.ALL_COMPLETED)

        if listener_task in done:
            comp_data = listener_task.result()
            comp_data += bytes([0, 0, 255, 255])
            json_message = decomp.decompress(comp_data).decode("utf-8")

            if json_message is None:
                break

            message = json.loads(json_message)
            if "msgs" in message:
                for m in message["msgs"]:
                    yield from handle_message(webs, m)
            elif "msg" in message:
                yield from handle_message(webs, message)
            else:
                print("Invalid message received: " + message)
                yield from webs.close()

        if producer_task in done:
            message = producer_task.result()
            if not webs.open:
                break
            if len(messages) == 0 and len(found_games) == len(update_games):
                print("All rcs updated, closing connection")
                yield from webs.close()
                break

if __name__ == '__main__':
    servers = {"cszo" : "ws://crawl.s-z.org/socket",
               "cao" : "ws://crawl.akrasiac.org:8080/socket",
               "cbro" : "ws://crawl.berotato.org:8080/socket"}
    games = ["trunk", "0.16"]
    default_servers = ",".join(sorted(servers.keys()))
    default_games = ",".join(games)

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-f", dest="rc_file", nargs=1, metavar="<rc-file>",
                        default=None, help="The rc file to use.")
    parser.add_argument("-u", dest="username", metavar="<username>",
                        help="The account username.", default=None)
    parser.add_argument("-p", dest="password", metavar="<password>",
                        help="The account password.", default=None)
    parser.add_argument("-s", dest="servers", metavar="<server1>[,<server2>,...]",
                        help="Comma-seperated list of servers to update "
                        "(default: %(default)s).", default=default_servers)
    parser.add_argument("-g", dest="games", metavar="<game1>[,<game2>,...]",
                        help="Comma-seperated list of games to update "
                        "(default: %(default)s).", default=default_games)
    args = parser.parse_args()

    rc_file = args.rc_file
    if rc_file is None:
        if os.path.isfile(os.environ["HOME"] + "/.crawl/init.txt"):
            rc_file = os.environ["HOME"] + "/.crawl/init.txt"
        elif os.path.isfile(os.environ["HOME"] + "/.crawlrc"):
            rc_file = os.environ["HOME"] + "/.crawlrc"
        else:
            sys.exit("No crawl rc found and none given with -f")

    update_servers = args.servers.split(",")
    for s in update_servers:
        if s not in servers:
            sys.exit("Unrecognized server: " + s)

    update_games = args.games.split(",")
    for g in update_games:
        if g not in games:
            sys.exit("Unrecognized game: " + g)

    rc_fh = open(rc_file, "rU")
    rc_text = rc_fh.read()

    username = args.username
    if not username:
        username = input("Crawl username: ")

    password = args.password
    if not password:
        password = getpass.getpass("Crawl password: ")

    decomp = zlib.decompressobj(-zlib.MAX_WBITS)
    for s in update_servers:
        num_rcs_updated = 0
        messages = []
        found_games = []
        print("Updating server " + s)
        asyncio.get_event_loop().run_until_complete(connect(servers[s]))
