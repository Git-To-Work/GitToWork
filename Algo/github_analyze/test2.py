import requests

BASE_URL = "https://jumpit-api.saramin.co.kr/api/positions?sort=rsp_rate&page={}"
url = BASE_URL.format(1)
response = requests.get(url)
print(response.text)
