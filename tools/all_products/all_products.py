#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
all_products: Create a list of all VMware products
Author: Alister Lewis-Bowen <alister@lewis-bowen.org>
"""

import requests
from bs4 import BeautifulSoup


vgm_url = 'https://docs.vmware.com/allproducts.html'
html_text = requests.get(vgm_url).text
soup = BeautifulSoup(html_text, 'html.parser')

links = soup.select('ul.product-list li a')

links = soup.select('ul.productsVerticalList > li ~ ul.product-list ~ li ~ a')

