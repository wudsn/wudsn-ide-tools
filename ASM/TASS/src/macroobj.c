/*
    $Id: macroobj.c 2691 2021-09-08 10:39:32Z soci $

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

*/
#include "macroobj.h"
#include "values.h"
#include "eval.h"
#include "error.h"
#include "file.h"

#include "typeobj.h"
#include "namespaceobj.h"
#include "intobj.h"
#include "noneobj.h"
#include "errorobj.h"

static Type macro_obj;
static Type segment_obj;
static Type struct_obj;
static Type union_obj;

Type *const MACRO_OBJ = &macro_obj;
Type *const SEGMENT_OBJ = &segment_obj;
Type *const STRUCT_OBJ = &struct_obj;
Type *const UNION_OBJ = &union_obj;

static FAST_CALL void macro_destroy(Obj *o1) {
    Macro *v1 = Macro(o1);
    const struct file_s *cfile = v1->file_list->file;
    argcount_t i;
    for (i = 0; i < v1->argc; i++) {
        const struct macro_param_s *param = &v1->param[i];
        if (not_in_file(param->cfname.data, cfile)) free((char *)param->cfname.data);
        if (not_in_file(param->init.data, cfile)) free((char *)param->init.data);
    }
    free(v1->param);
}

static FAST_CALL bool macro_same(const Obj *o1, const Obj *o2) {
    const Macro *v1 = Macro(o1), *v2 = Macro(o2);
    argcount_t i;
    if (o1->obj != o2->obj || v1->file_list != v2->file_list || v1->line != v2->line || v1->retval != v2->retval || v1->argc != v2->argc) return false;
    for (i = 0; i < v1->argc; i++) {
        if (str_cmp(&v1->param[i].cfname, &v2->param[i].cfname) != 0) return false;
        if (str_cmp(&v1->param[i].init, &v2->param[i].init) != 0) return false;
    }
    return true;
}

static FAST_CALL void struct_destroy(Obj *o1) {
    macro_destroy(o1);
    val_destroy(Obj(Struct(o1)->names));
}

static FAST_CALL void struct_garbage(Obj *o1, int i) {
    Struct *v1 = Struct(o1);
    Obj *v;
    switch (i) {
    case -1:
        Obj(v1->names)->refcount--;
        return;
    case 0:
        macro_destroy(o1);
        return;
    case 1:
        v = Obj(v1->names);
        if ((v->refcount & SIZE_MSB) != 0) {
            v->refcount -= SIZE_MSB - 1;
            v->obj->garbage(v, 1);
        } else v->refcount++;
        return;
    }
}

static FAST_CALL bool struct_same(const Obj *o1, const Obj *o2) {
    const Struct *v1 = Struct(o1), *v2 = Struct(o2);
    argcount_t i;
    if (o1->obj != o2->obj || v1->size != v2->size || v1->file_list != v2->file_list || v1->line != v2->line || v1->retval != v2->retval || v1->argc != v2->argc) return false;
    if (v1->names != v2->names && !v1->names->v.obj->same(Obj(v1->names), Obj(v2->names))) return false;
    for (i = 0; i < v1->argc; i++) {
        if (str_cmp(&v1->param[i].cfname, &v2->param[i].cfname) != 0) return false;
        if (str_cmp(&v1->param[i].init, &v2->param[i].init) != 0) return false;
    }
    return true;
}

static MUST_CHECK Obj *struct_size(oper_t op) {
    Struct *v1 = Struct(op->v2);
    return int_from_size(v1->size);
}

static MUST_CHECK Obj *struct_contains(oper_t op) {
    Obj *o1 = op->v1;
    Struct *v2 = Struct(op->v2);

    switch (o1->obj->type) {
    case T_SYMBOL:
    case T_ANONSYMBOL:
        op->v2 = Obj(v2->names);
        return v2->names->v.obj->contains(op);
    case T_NONE:
    case T_ERROR:
        return val_reference(o1);
    default:
        return obj_oper_error(op);
    }
}

static MUST_CHECK Obj *struct_calc2(oper_t op) {
    if (op->op == O_MEMBER) {
        return namespace_member(op, Struct(op->v1)->names);
    }
    if (op->v2 == none_value || op->v2->obj == ERROR_OBJ) return val_reference(op->v2);
    return obj_oper_error(op);
}

void macroobj_init(void) {
    Type *type = new_type(&macro_obj, T_MACRO, "macro", sizeof(Macro));
    type->destroy = macro_destroy;
    type->same = macro_same;

    type = new_type(&segment_obj, T_SEGMENT, "segment", sizeof(Segment));
    type->destroy = macro_destroy;
    type->same = macro_same;

    type = new_type(&struct_obj, T_STRUCT, "struct", sizeof(Struct));
    type->destroy = struct_destroy;
    type->garbage = struct_garbage;
    type->same = struct_same;
    type->size = struct_size;
    type->calc2 = struct_calc2;
    type->contains = struct_contains;

    type = new_type(&union_obj, T_UNION, "union", sizeof(Union));
    type->destroy = struct_destroy;
    type->garbage = struct_garbage;
    type->same = struct_same;
    type->size = struct_size;
    type->calc2 = struct_calc2;
    type->contains = struct_contains;
}
