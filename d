import discord
from discord.ext import commands
import requests
import time
import random
import threading

config = {
    "key": "captcha.rip key here",
    "prefix": "acier_",
    "threads": 20
}

intents = discord.Intents.default()
intents.typing = False
intents.presences = False

bot = commands.Bot(command_prefix='/', intents=intents)

@bot.event
async def on_ready():
    print("Bot is ready")

async def grandom(rtype="password"):
    return f"{config['prefix']}{''.join((random.choice('abcdyzpqrABCDYZPQR') for i in range(8)))}"

def csrf(proxy, cookie=None):
    proxysplit = proxy.split(':')
    proxies = {
        'https': f'http://{proxysplit[2]}:{proxysplit[3]}@{proxysplit[0]}:{proxysplit[1]}'
    }
    return requests.post("https://auth.roblox.com/v2/logout", proxies=proxies, cookies={".ROBLOSECURITY": cookie}).headers["x-csrf-token"] if cookie else requests.post('https://catalog.roblox.com/v1/catalog/items/details', proxies=proxies).headers['x-csrf-token']

async def registerinfo(proxy):
    async with requests.Session() as session:
        proxysplit = proxy.split(':')
        proxies = {
            'https': f'http://{proxysplit[2]}:{proxysplit[3]}@{proxysplit[0]}:{proxysplit[1]}'
        }
        cdetails = await session.post("https://auth.roblox.com/v2/signup", proxies=proxies, headers={"x-csrf-token":csrf(proxy), "User-Agent":"Mozilla/5.0 (Windows; U; Windows CE) AppleWebKit/534.47.7 (KHTML, like Gecko) Version/4.1 Safari/534.47.7"}, json={"username":"fsdhfkshdfk123","password":"WE*@*!&EUAHUISFHS","birthday":"1962-04-08T23:00:00.000Z","gender":2,"isTosAgreementBoxChecked":True,"agreementIds":["848d8d8f-0e33-4176-bcd9-aa4e22ae7905","54d8a8f0-d9c8-4cf3-bd26-0cbf8af0bba3"]})
        if cdetails.status_code != 429:
            return cdetails.json()["errors"][0]["fieldData"].split(",")[0], cdetails.json()["errors"][0]["fieldData"].split(",")[1]
        else:
            print('too many requested on registerinfo, retrying.')
            time.sleep(1)
            return await registerinfo(proxy)

async def solve(blob, pkey):
    solvej = {
      "key": pkey,
      "task": {
          "type": "FunCaptchaTaskProxyless",
          "site_url": "https://www.roblox.com/",
          "public_key": pkey,
          "service_url": "https://roblox-api.arkoselabs.com/",
          "blob": blob
      }
    }
    create = requests.post('https://captcha.rip/api/create', json=solvej)
    if not "id" in create.text:
        print("error", create.text)
        return False
    checkj = {
        'key': config['key'],
        'id': create.json()['id']
    }
    fetch = requests.post('https://captcha.rip/api/fetch', json=checkj)
    while fetch.json()['message'] == 'Processing':
        time.sleep(1)
        fetch = requests.post('https://captcha.rip/api/fetch', json=checkj)
    if fetch.json()['message'] == 'Solved':
        print(f'solved! {fetch.text}')
        return fetch.json()['token']
    else:
        print(f'failed {fetch.text}')
        return False

@bot.command()
async def main(ctx):
    while True:
        proxy = next(proxies).strip()
        cid, blob = await registerinfo(proxy)
        solved = await solve(blob, pkeys['ACTION_TYPE_WEB_SIGNUP'])
        if solved:
            await register(cid, solved, proxy, ctx)

async def register(cid, token, proxy, ctx):
    username = await grandom('username')
    password = await grandom('password')
    proxysplit = proxy.split(':')
    registerj = {
        'agreementIds': ["848d8d8f-0e33-4176-bcd9-aa4e22ae7905", "54d8a8f0-d9c8-4cf3-bd26-0cbf8af0bba3"],
        'birthday': "1996-04-05T08:00:00.000Z",
        'captchaId': cid,
        'captchaToken': token, 
        'gender': 1,
        'isTosAgreementBoxChecked': True,
        'username': username,
        'password': password
    }
    register_proxies = {
        'https': f'http://{proxysplit[2]}:{proxysplit[3]}@{proxysplit[0]}:{proxysplit[1]}'
    }
    attemptregister = requests.post('https://auth.roblox.com/v2/signup', headers={'x-csrf-token': csrf(proxy)}, json=registerj, proxies=register_proxies)
    if attemptregister.status_code == 200:
        print(f'successfully registered {username}:{password} on {proxy}')
        with open('cookies.txt', 'a+') as cookiesfile:
            cookiesfile.write(f'{username}:{password}:{attemptregister.cookies[".ROBLOSECURITY"]}\n')
        with open('formatted.txt', 'a+') as formattedfile:
            formattedfile.write(f'{username}:{password}:{proxy}:{attemptregister.cookies[".ROBLOSECURITY"]}\n')
        await ctx.send(f'Successfully registered {username}:{password} on {proxy}')
    elif attemptregister.status_code == 429:
        print('too many requests when registering, retrying.')
        time.sleep(3)
        cid, blob = await registerinfo(proxy)
        return await register(cid, solve(blob), proxy, ctx)
    else:
        print(attemptregister.text, attemptregister.status_code)

for _ in range(config['threads']):
    threading.Thread(target=main).start()

bot.run('MTE0MDY0MDQyMDU2NTYyMjgyNA.Gy5CMl.LeVoEzDjrdoT8UivUKFLvD_bLhbPIiMryQDTnk')
