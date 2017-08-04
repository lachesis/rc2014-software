#!/usr/bin/python3
import argparse
import sys
import re
import logging

logger = logging.getLogger(__name__)

PAGE_SIZE = 8 * 1024
ROM_SIZE = 64 * 1024

#PAGE_SIZE = 16 * 1024
#ROM_SIZE = 512 * 1024

assert ROM_SIZE >= PAGE_SIZE
assert ROM_SIZE % PAGE_SIZE == 0

def build_rom(pages):
    rom = bytearray(b'\xff' * ROM_SIZE)
    for i, page in enumerate(pages):
        if not page:
            continue
        size = len(page)
        if size > PAGE_SIZE:
            raise ValueError("Page #{} is {} bytes, bigger than {} page size".format(i, size, PAGE_SIZE))
        rom[PAGE_SIZE*i:PAGE_SIZE*(i+1)] = page + b'\xff' * (PAGE_SIZE - size)
    rom = bytes(rom)
    return rom

def split_rom(rom):
    # Split the ROM into pages, skipping ones that are completely \xff
    pages = []
    for i in range(ROM_SIZE // PAGE_SIZE):
        page = rom[PAGE_SIZE*i:PAGE_SIZE*(i+1)]
        page += b'\xff' * (PAGE_SIZE - len(page))
        if page == b'\xff' * PAGE_SIZE:
            page = None
        pages.append(page)
    return pages

def action_build_rom(args):
    page_specs = []
    for fspec in args.input_files:
        page_num, fn = re.match(r'^(\d+:)?(.*)$', fspec).groups()
        if page_num is not None:
            page_num = int(page_num.strip(':'))
        page_specs.append((page_num, fn))

    if len(page_specs) > ROM_SIZE // PAGE_SIZE:
        raise ValueError("Too many pages provided!")

    pages = [None] * (ROM_SIZE // PAGE_SIZE)
    free_pages = set(range(len(pages)))
    for page_num, fn in page_specs:
        if page_num is None:
            try:
                page_num = free_pages.pop()  # "KeyError: pop from an empty set" if empty
            except KeyError:
                raise ValueError("No free page number!")
        else:
            try:
                free_pages.remove(page_num)
            except KeyError:
                raise ValueError("Page number %s is used twice!" % page_num)

        with open(fn, 'rb') as inp:
            data = inp.read()

        pages[page_num] = data

    rom = build_rom(pages)

    if args.output:
        with open(args.output, 'wb') as out:
            out.write(rom)
    else:
        sys.stdout.write(rom)

def action_split_rom(args):
    with open(args.input_file, 'rb') as inp:
        rom = inp.read()

    pages = split_rom(rom)
    for i, page in enumerate(pages):
        if page is None:
            continue
        with open('{0}-page{1:02d}.bin'.format(args.input_file, i), 'wb') as out:
            out.write(page)

def main():
    logging.basicConfig(level=logging.DEBUG)

    parser = argparse.ArgumentParser(description="Tools for working with paged ROM files")
    subparser = parser.add_subparsers()

    parser_join = subparser.add_parser('join', help="Build a paged ROM out of multiple BIN files")
    parser_join.add_argument("-o", "--output", type=str, help="Output path (optional, defaults to stdout)")
    parser_join.add_argument("input_files", nargs='+', help="Input files, optionally prepended with 0-indexed decimal page number, e.g. 3:romwbw.bin")
    parser_join.set_defaults(func=action_build_rom)

    parser_split = subparser.add_parser('split', help="Break a ROM file into its pages")
    parser_split.add_argument("input_file", help="Input BIN file")
    parser_split.set_defaults(func=action_split_rom)

    args = parser.parse_args()

    if not hasattr(args, 'func'):
        parser.print_help()
        return

    args.func(args)

if __name__ == '__main__':
    main()
