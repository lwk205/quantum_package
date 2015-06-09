#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Create the NEEDED_MODULE
    aka the genealogy (children module, subchildren module and so on),
of a NEEDED_CHILDREN_MODULES file

Usage:
    module_handler.py print_descendant      [<NEEDED_CHILDREN_MODULES>]
    module_handler.py create_png            [<NEEDED_CHILDREN_MODULES>]

Options:
    print_descendant         Print the genealogy of the NEEDED_CHILDREN_MODULES
                                 aka (children, subchildren, etc)
    create_png              Create a png of the file
    NEEDED_CHILDREN_MODULES The path of NEEDED_CHILDREN_MODULES
                                by default try to open the file in the current path
"""
import os
import sys
import os.path
from collections import namedtuple

try:
    from docopt import docopt
except ImportError:
    print "source .quantum_package.rc"
    raise


# Canot cache for namedtuple are not hashable
def get_dict_child(l_root_abs=None):
    """Loop over MODULE in  QP_ROOT/src, open all the NEEDED_CHILDREN_MODULES
    and create a dict[MODULE] = [sub module needed, ...]
    """
    d_ref = dict()

    if not l_root_abs:
        qp_root = os.environ['QP_ROOT']
        l_root_abs = [os.path.join(qp_root, 'src')]

    for root_abs in l_root_abs:
        for module_rel in os.listdir(root_abs):

            module_abs = os.path.join(root_abs, module_rel)
            try:
                path_file = os.path.join(module_abs, "NEEDED_CHILDREN_MODULES")

                with open(path_file, "r") as f:
                    l_children = f.read().split()
            except IOError:
                pass
            else:
                if module_rel not in d_ref:
                    d_ref[module_rel] = l_children
                else:
                    print "Module {0} alredy defined"
                    print "Abort"
                    sys.exit(1)

    return d_ref


def l_module_descendant(d_child, l_module):
    """
    From a list of module return the module and descendant
    """

    l = []
    for module in l_module:
        if module not in l:
            l.append(module)
            try:
                l.extend(l_module_descendant(d_child, d_child[module]))
            except KeyError:
                print >> sys.stderr, "`{0}` not submodule".format(module)
                print >> sys.stderr, "Check the corresponding NEEDED_CHILDREN_MODULES"
                sys.exit(1)

    return list(set(l))


class ModuleHandler():

    def __init__(self, l_root_abs=None):
        self.dict_child = get_dict_child(l_root_abs)

    @property
    def l_module(self):
        return self.dict_child.keys()

    @property
    def dict_parent(self):
        """
        Get a dic of the first parent
        """
        d_child = self.dict_child

        d = {}

        for module_name in d_child:
            d[module_name] = [i for i in d_child.keys() if module_name in d_child[i]]

        return d

    @property
    def dict_descendant(self):
        """
        Get a dic of all the genealogy desc (children and all_children)
        """
        d = {}

        d_child = self.dict_child

        for module_name in d_child:
            d[module_name] = l_module_descendant(d_child,
                                                 d_child[module_name])

        return d

    @property
    def dict_root(self):
        """
        Return a dict(module_name) = module_boss
        The top node in a tree.
        """
        d_asc = self.dict_parent
        d_desc = self.dict_descendant

        l_all_module = self.l_module

        dict_root = {}

        for module in l_all_module:
            dict_root[module] = [ p for p in l_all_module if module in [p] + d_desc[p] and not d_asc[p]][0]

        return dict_root

    def l_descendant_unique(self, l_module):
        d_desc = self.dict_descendant

        d = {}
        for module in l_module:
            for e in d_desc[module]:
                d[e] = 1

        return d.keys()

    def l_reduce_tree(self, l_module):
        """For a list of module in input return only the root"""
        l_d_u = self.l_descendant_unique(l_module)
        l_module_reduce = []
        for module in l_module:
            if module not in l_d_u:
                l_module_reduce.append(module)

        return l_module_reduce

    def create_png(self, l_module):
        """Create the png of the dependency tree for a l_module"""

        # Init
        import pydot
        all_ready_done = []

        def draw_module_edge(module, l_children):
            "Draw all the module recursifly"

            if module not in all_ready_done:
                for children in l_children:
                    # Add Edge
                    edge = pydot.Edge(module, children)
                    graph.add_edge(edge)
                    # Recurs
                    draw_module_edge(children, d_ref[children])
                all_ready_done.append(module)

        # Init
        graph = pydot.Dot(graph_type='digraph')
        d_ref = self.dict_child

        # Create all the edge
        for module in l_module:
            node_a = pydot.Node(module, fontcolor="red")
            graph.add_node(node_a)
            draw_module_edge(module, d_ref[module])

        # Save
        path = '{0}.png'.format("tree_dependency")
        graph.write_png(path)


if __name__ == '__main__':

    arguments = docopt(__doc__)

    if not arguments['<NEEDED_CHILDREN_MODULES>']:
        dir_ = os.getcwd()
    else:
        path_file = os.path.abspath(arguments['<NEEDED_CHILDREN_MODULES>'])
        path_file = os.path.expanduser(path_file)
        path_file = os.path.expandvars(path_file)
        dir_ = os.path.dirname(path_file)

    path_file = os.path.basename(dir_)
    m = ModuleHandler()

    if arguments['print_descendant']:
        print " ".join(sorted(m.l_module))

    if arguments["create_png"]:
        m.create_png([path_file])
