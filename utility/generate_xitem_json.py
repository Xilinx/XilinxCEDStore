import sys
import json
import argparse
from xml.dom import minidom
from collections import OrderedDict

def extractData(xmlnode) :
	value = ""
	deslen = len(xmlnode)
	if deslen > 0 :
		des = xmlnode[0].firstChild
		if des:
			value = des.nodeValue.strip()
	return value		

def createXitemJson(xmldoc,args) :

	subtype = "examples"	
	nameNode = xmldoc.getElementsByTagName("Name")
	name = extractData(nameNode)
	dsnameNode = xmldoc.getElementsByTagName("DisplayName")
	dsname = extractData(dsnameNode)
	vendorNode = xmldoc.getElementsByTagName("Vendor")
	vendor = extractData(vendorNode)
	verNode = xmldoc.getElementsByTagName("Version")
	ver = extractData(verNode)
	descrNode = xmldoc.getElementsByTagName("Description")	
	descr = extractData(descrNode) 
		
	data = OrderedDict()
	config = OrderedDict()
	search_keywords = [name,vendor,subtype]
	
	orderItem = OrderedDict()
	company_name = vendor
	if (args.company_display_name !=""):
		vendor = args.company_display_name	
	
	orderItem["name"]  = name
	orderItem["display"] = dsname
	orderItem["revision"] = ver
	orderItem["description"] = descr
	orderItem["company"] = company_name
	orderItem["company_display"] = vendor
	orderItem["author"] = args.author
	
	contributor = OrderedDict()
	
	contributor['group'] = vendor
	contributor["url"] = args.company_url
	contributors = [contributor]
	
	orderItem["contributors"] = contributors
	orderItem["category"] = args.category
	orderItem["website"] = args.company_url
	orderItem["is_active"] = True
	if (args.dependency_item !=""):		
		dependency = OrderedDict()
		dependency["store"] = args.dependency_item_store
		dependency["company"] = args.dependency_item_company
		dependency["item"] = args.dependency_item
		if (args.dependency_item_revision != ""):
			dependency["revision"] = args.dependency_item_revision
		dependencies = [dependency]
		orderItem["dependencies"] = dependencies	
 
	orderItem["search-keywords"] = search_keywords
	
	item = OrderedDict()
	item["infra"] = orderItem
	
	orderItems = [item]
	config['items'] = orderItems
	data['config'] = config
	data["_major"] = 1
	data["_minor"] = 0

	try:	
		outfile = open(args.output_file,'w')
	except IOError:
		print ('cannot open', args.output_file)
	else:
		json.dump(data, outfile,indent = 2)
		outfile.close()

def parse_cmdline():

    parser = argparse.ArgumentParser(description='Utility python script',
            epilog="Utility script to create xitem.json from design.xml .")
    parser.add_argument('--design_file', help="Path of the design.xml file", required = True)
    parser.add_argument('--author', help="Author of the example design ", required = True)
    parser.add_argument('--category', help="category the example design/board belongs to.(Single part/ Multi part,...)  ", required = True)
    parser.add_argument('--company_display_name', help="Comapny of the board", required = True, default = "")
    parser.add_argument('--company_url', help="Comapny URL ", required = True,default = "")
    parser.add_argument('--dependency_item', help="name of dependency item ", required = False,default = "")
    parser.add_argument('--dependency_item_store', help="store of dependency item ", required = False,default = "xilinx_board_store")
    parser.add_argument('--dependency_item_revision', help="revision of dependency item ", required = False,default = "")
    parser.add_argument('--dependency_item_company', help="Company of dependency item ", required = False,default = "")

    parser.add_argument('--output_file', help="Refers to the outputfile, default: xitem.json ", required = False, default = "xitem.json")
    return parser

def main():
	parser = parse_cmdline()
	args = parser.parse_args() 
	try : 
		infile= open(args.design_file,"r")
	except IOError:
		print ('cannot open', args.design_file)
	else:
		infile.close()
		xmldoc = minidom.parse(args.design_file)	
		createXitemJson(xmldoc,args)

if __name__ == '__main__': main()
