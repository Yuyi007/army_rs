#include "skynet_env.h"
#include "skynet_log.h"
#include "skynet_timer.h"
#include "skynet.h"
#include "skynet_socket.h"


#include <lua.h>
#include <lauxlib.h>

#include <stddef.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include <stdlib.h>

//#define AOI_RADIUS 10.0f

#define INVALID_ID (~0)
#define PRE_ALLOC 16
//#define AOI_RADIUS2 (AOI_RADIUS * AOI_RADIUS)
#define DIST2(p1,p2) ((p1[0] - p2[0]) * (p1[0] - p2[0]) + (p1[1] - p2[1]) * (p1[1] - p2[1]) + (p1[2] - p2[2]) * (p1[2] - p2[2]))
#define MODE_WATCHER 1
#define MODE_MARKER 2
#define MODE_MOVE 4
#define MODE_DROP 8
#define MAX_UID_LEN 127


typedef void * (*aoi_Alloc)(void *ud, void * ptr, size_t sz);


struct object {
  int ref;
  char id[MAX_UID_LEN + 1];
  //int version;
  //int mode;
  //uint32_t last[3];
  uint32_t position[3];

  struct object_list* pos_iter[3];
  struct object_list* in_sight_list_iter;
};

struct object_set {
  int cap;
  int number;
  struct object ** slot;
};

//第一个元素为head，没有意义
//index==0时，指向第二个元素
struct object_list{
  struct object* obj;
  struct object_list* next;
  struct object_list* prev;
};

struct pair_list {
  struct pair_list * next;
  struct object * watcher;
  struct object * marker;
  int watcher_version;
  int marker_version;
};

struct map_slot {
  char id[MAX_UID_LEN + 1];
  struct object * obj;
  int next;
};

struct map {
  int size;
  int lastfree;
  struct map_slot * slot;
};

typedef struct aoi_space {
  aoi_Alloc alloc;
  void * alloc_ud;
  struct map * object;

  struct pair_list * hot;

  //===============================
  struct object_list* x_list;
  struct object_list* y_list;
  struct object_list* z_list;

  struct object_list* in_sight_list;

  uint32_t radius;
  uint32_t radius2;
}aoi_space;


//static struct aoi_space* g_space = NULL;
//static uint32_t g_radius = 10;
//static uint32_t g_radius2 = 100;



static void copy_uid(char* dst, const char* src)
{
  if (strlen(src) > MAX_UID_LEN)
  {
    strlcpy(dst, src, MAX_UID_LEN);
    dst[MAX_UID_LEN] = 0;
  }
  else
  {
    strcpy(dst, src);
  }
}

inline static void copy_position(uint32_t des[3], uint32_t src[3])
{
  des[0] = src[0];
  des[1] = src[1];
  des[2] = src[2];
}

static uint32_t gen_hash(struct map *m, const char* id)
{
  uint32_t base = 0;
  int i, j;
  for(i=32; i > 0; i--)
  {
    if(strlen(id) >= i)
    {
      int max = strlen(id) > 32 ? 32:strlen(id);
      for(j = 0; j < max; j++)
      {
        base += id[i];
      }
      break;
    }
  }
  return base & (m->size-1);
}

static struct object *
new_object(struct aoi_space * space, const char* id) {
  struct object * obj = space->alloc(space->alloc_ud, NULL, sizeof(*obj));
  obj->ref = 1;
  copy_uid(obj->id, id);
  obj->pos_iter[0] = NULL;
  obj->pos_iter[1] = NULL;
  obj->pos_iter[2] = NULL;
  obj->in_sight_list_iter = NULL;
  return obj;
}

static inline struct map_slot *
mainposition(struct map *m , const char* id) {
  uint32_t hash = gen_hash(m, id);//id[0] & (m->size-1);
  return &m->slot[hash];
}

static void rehash(struct aoi_space * space, struct map *m);

static void
map_insert(struct aoi_space * space , struct map * m, const char* id , struct object *obj) {
  struct map_slot *s = mainposition(m,id);
  if (strlen(s->id) == 0) {
    copy_uid(s->id, id);
    //s->id = id;
    s->obj = obj;
    return;
  }
  if (mainposition(m, s->id) != s) {
    struct map_slot * last = mainposition(m,s->id);
    while (last->next != s - m->slot) {
      assert(last->next >= 0);
      last = &m->slot[last->next];
    }
    char temp_id[MAX_UID_LEN + 1];
    memset((void*)temp_id, 0, MAX_UID_LEN + 1);
    copy_uid(temp_id, s->id);
    struct object * temp_obj = s->obj;
    last->next = s->next;
    copy_uid(s->id, id);
    s->obj = obj;
    s->next = -1;
    if (temp_obj) {
      map_insert(space, m, temp_id, temp_obj);
    }
    return;
  }
  while (m->lastfree >= 0) {
    struct map_slot * temp = &m->slot[m->lastfree--];
    if (strlen(temp->id) == 0) {
      copy_uid(temp->id, id);
      //temp->id = id;
      temp->obj = obj;
      temp->next = s->next;
      s->next = (int)(temp - m->slot);
      return;
    }
  }
  rehash(space,m);
  map_insert(space, m, id , obj);
}

static void
rehash(struct aoi_space * space, struct map *m) {
  struct map_slot * old_slot = m->slot;
  int old_size = m->size;
  m->size = 2 * old_size;
  m->lastfree = m->size - 1;
  m->slot = space->alloc(space->alloc_ud, NULL, m->size * sizeof(struct map_slot));
  int i;
  for (i=0;i<m->size;i++) {
    struct map_slot * s = &m->slot[i];
    memset(s->id, 0, MAX_UID_LEN + 1);
    //s->id = INVALID_ID;
    s->obj = NULL;
    s->next = -1;
  }
  for (i=0;i<old_size;i++) {
    struct map_slot * s = &old_slot[i];
    if (s->obj) {
      map_insert(space, m, s->id, s->obj);
    }
  }
  space->alloc(space->alloc_ud, old_slot, old_size * sizeof(struct map_slot));
}

static struct object *
map_query(struct aoi_space *space, struct map * m, const char* id) {
  struct map_slot *s = mainposition(m, id);
  for (;;) {
    if (strcmp(s->id, id) == 0) {
      if (s->obj == NULL) {
        s->obj = new_object(space, id);
      }
      return s->obj;
    }
    if (s->next < 0) {
      break;
    }
    s=&m->slot[s->next];
  }
  struct object * obj = new_object(space, id);
  map_insert(space, m , id , obj);
  return obj;
}

static struct object *
map_find(struct aoi_space *space, struct map * m, const char* id) {
  struct map_slot *s = mainposition(m, id);
  for (;;) {
    if (strcmp(s->id, id) == 0) {
      if (s->obj == NULL) {
        s->obj = new_object(space, id);
      }
      return s->obj;
    }
    if (s->next < 0) {
      break;
    }
    s=&m->slot[s->next];
  }
  return NULL;
}

static void
map_foreach(struct map * m , void (*func)(void *ud, struct object *obj), void *ud) {
  int i;
  for (i=0;i<m->size;i++) {
    if (m->slot[i].obj) {
      func(ud, m->slot[i].obj);
    }
  }
}

static struct object *
map_drop(struct map *m, const char* id) {
  uint32_t hash = gen_hash(m, id);//id[0] & (m->size-1);
  struct map_slot *s = &m->slot[hash];
  for (;;) {
    if (strcmp(s->id, id) == 0) {
      struct object * obj = s->obj;
      s->obj = NULL;
      return obj;
    }
    if (s->next < 0) {
      return NULL;
    }
    s=&m->slot[s->next];
  }
}

static void
map_delete(struct aoi_space *space, struct map * m) {
  space->alloc(space->alloc_ud, m->slot, m->size * sizeof(struct map_slot));
  space->alloc(space->alloc_ud, m , sizeof(*m));
}

static struct map *
map_new(struct aoi_space *space) {
  int i;
  struct map * m = space->alloc(space->alloc_ud, NULL, sizeof(*m));
  m->size = PRE_ALLOC;
  m->lastfree = PRE_ALLOC - 1;
  m->slot = space->alloc(space->alloc_ud, NULL, m->size * sizeof(struct map_slot));
  for (i=0;i<m->size;i++) {
    struct map_slot * s = &m->slot[i];
    memset((void*)(s->id), 0, MAX_UID_LEN);
    //s->id = INVALID_ID;
    s->obj = NULL;
    s->next = -1;
  }
  return m;
}

inline static void
grab_object(struct object *obj) {
  ++obj->ref;
}

static void
delete_object(void *s, struct object * obj) {
  struct aoi_space * space = s;
  space->alloc(space->alloc_ud, obj, sizeof(*obj));
}

static void list_remove_node(struct object_list* node);
inline static void
drop_object(struct aoi_space * space, struct object *obj) {
  --obj->ref;
  if (obj->ref <=0) {
    int i;
    for(i = 0; i < 3; i++)
    {
      if(obj->pos_iter[i])
      {
        list_remove_node(obj->pos_iter[i]);
        space->alloc(space->alloc_ud, obj->pos_iter[i], sizeof(*(obj->pos_iter[i])));
      }
      if(obj->in_sight_list_iter)
      {
        list_remove_node(obj->in_sight_list_iter);
        space->alloc(space->alloc_ud, obj->in_sight_list_iter, sizeof(*(obj->in_sight_list_iter)));
      }
    }
    map_drop(space->object, obj->id);
    delete_object(space, obj);
  }
}


static void list_remove_node(struct object_list* node)
{
  //printf("1, %d, %d\n", node, node->obj);
  if((node == NULL) || (node->obj == NULL))
  {
    //printf("2\n");
    return;
  }
  //printf("3\n");
  struct object_list* prev = node->prev;
  //printf("4\n");
  if(node->next)
  {
    //printf("5\n");
    node->next->prev = node->prev;
  }
  //printf("6\n");
  if(prev)
  {
    //printf("7\n");
    prev->next = node->next;
  }
  //printf("8\n");
  node->next = NULL;
  node->prev = NULL;
}

static void list_clear_all_node(struct object_list* l)
{
  struct object_list* node = l->next;
  l->next = NULL;
  while(node && node->obj)
  {
    struct object_list* tmp = node->next;
    node->next = NULL;
    node->prev = NULL;
    node = tmp;
  }
  l->next = node;
  l->prev = NULL;
  node->next = NULL;
  node->prev = l;
}

static struct object_list* list_new(struct aoi_space *space)
{
  struct object_list* head = space->alloc(space->alloc_ud, NULL, sizeof(*head));
  struct object_list* tail = space->alloc(space->alloc_ud, NULL, sizeof(*tail));
  head->obj = NULL;
  tail->obj = NULL;
  head->next = tail;
  head->prev = NULL;
  tail->next = NULL;
  tail->prev = head;
  return head;
}

static struct object_list* list_node_new(struct aoi_space *space, struct object* obj)
{
  struct object_list* l = space->alloc(space->alloc_ud, NULL, sizeof(*l));
  l->next = NULL;
  l->prev = NULL;
  if(obj)
  {
    l->obj = obj;
  }
  return l;
}

static void list_delete(struct aoi_space *space, struct object_list* l)
{
  //todo
  while(l)
  {
    struct object_list* node = l;
    //struct object* obj = node->obj;
    struct object_list* next = node->next;
    space->alloc(space->alloc_ud, node, sizeof(*node));
    l = next;
  }
}


//插入链条中pos的前面，也就是取代原来pos的位置
static struct object_list* list_insert(struct aoi_space *space, struct object* obj, struct object_list* pos, struct object_list** p_old_iter, struct object_list* list)
{
  if(p_old_iter == NULL)
  {
    return NULL;
  }
  struct object_list* node = NULL;
  if(*p_old_iter)
  {
    node = *p_old_iter;
  }
  else
  {
    node = list_node_new(space, obj);
    *p_old_iter = node;
  }

  //printf("1111\n");
  list_remove_node(node);
  //printf("2222\n");

  if(pos)
  {
    if(pos->prev)
    {
      pos->prev->next = node;
      node->prev = pos->prev;
    }
    else
    {
      node->prev = NULL;
    }
    node->next = pos;
    pos->prev = node;
  }
  else
  {
    if(list->next)
    {
      list->next->prev = node;
      node->next = list->next;
    }
    list->next = node;
    node->prev = list;
  }
  return node;
}

static struct object_list* list_push_head(struct aoi_space *space, struct object_list* l, struct object* obj, struct object_list** p_old_iter)
{
  struct object_list* node = list_insert(space, obj, l->next, p_old_iter, l);
  return node;
}

static void dump_list(struct aoi_space* space, struct object_list* head, const char* msg)
{
  struct object_list* tmp = head->next;
  while(tmp && tmp->obj)
  {
    printf("%s, posx:%d, posy:%d, posz:%d, uid:%s, radius:%d, radius2:%d\n", msg, tmp->obj->position[0], tmp->obj->position[1], tmp->obj->position[2], tmp->obj->id, space->radius, space->radius2);
    tmp = tmp->next;
  }
}

static void *
default_alloc(void * ud, void *ptr, size_t sz) {
  if (ptr == NULL) {
    void *p = malloc(sz);
    return p;
  }
  free(ptr);
  return NULL;
}

/*
struct aoi_space * 
aoi_create(aoi_Alloc alloc, void *ud) {
  struct aoi_space *space = alloc(ud, NULL, sizeof(*space));
  space->alloc = alloc;
  space->alloc_ud = ud;
  space->object = map_new(space);
  space->x_list = list_new(space);
  space->y_list = list_new(space);
  space->z_list = list_new(space);
  space->in_sight_list = list_new(space);
  return space;
}

struct aoi_space * 
aoi_new() {
  return aoi_create(default_alloc, NULL);
}
*/

struct aoi_space * 
aoi_init(struct aoi_space* space) {
  //struct aoi_space *space = alloc(ud, NULL, sizeof(*space));
  space->alloc = default_alloc;
  space->alloc_ud = NULL;
  space->object = map_new(space);
  space->x_list = list_new(space);
  space->y_list = list_new(space);
  space->z_list = list_new(space);
  space->in_sight_list = list_new(space);
  space->radius = 200;
  space->radius2 = 40000;
  return space;
}

void 
aoi_release(struct aoi_space *space) {
  map_foreach(space->object, delete_object, space);

  map_delete(space, space->object);
  list_delete(space, space->x_list);
  list_delete(space, space->y_list);
  list_delete(space, space->z_list);
  list_delete(space, space->in_sight_list);

  //space->alloc(space->alloc_ud, space, sizeof(*space));
}

static void get_range_list(struct aoi_space* space, struct object* obj)
{
  if(obj->pos_iter[0] == NULL || obj->pos_iter[1] == NULL || obj->pos_iter[2] == NULL)
  {
    return;
  }

  struct map* m[2];
  m[0] = map_new(space);
  m[1] = map_new(space);

  int i;
  for(i = 0; i < 3; i++)
  {
    struct object_list* l = obj->pos_iter[i]->next;
    struct object_list* node = obj->pos_iter[i];
    while(l && l->obj)
    {
      //printf("<--------1 index:%d, uid:%s, posx:%d, posy:%d\n", i, l->obj->id, l->obj->position[0], l->obj->position[1]);
      struct object* ob = l->obj;
      //printf("next, >>>>> i:%d, ob->position[i]:%d, obj->position[i]:%d\n", i, ob->position[i], obj->position[i]);
      if((int)(ob->position[i] - obj->position[i]) <= (int)(space->radius) )
      {
        if(i == 0)
        {
          //printf("<<<<1\n");
          map_insert(space, m[i], ob->id, ob);
        }
        else if(i == 1)
        {
          //printf("<<<<2\n");
          if(map_find(space, m[i-1], ob->id) != NULL)
          {
            //printf("<<<<3\n");
            map_insert(space, m[i], ob->id, ob);
          }
        }
        else
        {
          //printf("<<<<4\n");
          if(map_find(space, m[i-1], ob->id) != NULL && DIST2(ob->position, obj->position) <= space->radius2)
          {
            //printf("<<<<5\n");
            struct object_list* n = list_push_head(space, space->in_sight_list, ob, &(ob->in_sight_list_iter));
          }
        }
      }
      else
      {
        break;
      }
      //printf("<<<<6\n");
      struct object_list * next = l->next;
      l = next;
      //printf("<<<<7\n");
    }
    //printf("<<<<8\n");

    l = obj->pos_iter[i]->prev;
    node = obj->pos_iter[i];
    while(l && l->obj)
    {
      //printf("<--------2 index:%d, uid:%s, posx:%d, posy:%d\n", i, l->obj->id, l->obj->position[0], l->obj->position[1]);
      //printf("<<<<9\n");
      struct object* ob = l->obj;
      if(ob == NULL)
      {
        //printf("<<<<10\n");
        break;
      }
      //printf("<<<<11\n");
      //printf("prev, >>>>> i:%d, ob->position[i]:%d, obj->position[i]:%d\n", i, ob->position[i], obj->position[i]);
      if((int)(obj->position[i] - ob->position[i]) <= (int)(space->radius) )
      {
        if(i == 0)
        {
          //printf("<<<<12\n");
          map_insert(space, m[i], ob->id, ob);
        }
        else if(i == 1)
        {
          //printf("<<<<13\n");
          if(map_find(space, m[i-1], ob->id) != NULL)
          {
            //printf("<<<<14\n");
            map_insert(space, m[i], ob->id, ob);
          }
        }
        else
        {
          //printf("<<<<15\n");
          if(map_find(space, m[i-1], ob->id) != NULL && DIST2(ob->position, obj->position) <= space->radius2)
          {
            //printf("<<<<16\n");
            struct object_list* n = list_push_head(space, space->in_sight_list, ob, &(ob->in_sight_list_iter));
            //printf(">>>>16\n");
          }
        }
      }
      else
      {
        break;
      }
      //printf("<<<<17\n");
      struct object_list * prev = l->prev;
      l = prev;
      //printf("<<<<18\n");
    }
  }
  //printf("<<<<19\n");

  map_delete(space, m[0]);
  map_delete(space, m[1]);
}

static void update_obj_pos(struct aoi_space* space, struct object* obj, uint32_t pos[3])
{
  if(obj->pos_iter[0] == NULL || obj->pos_iter[1] == NULL || obj->pos_iter[2] == NULL)
  {
    return;
  }
  uint32_t old_pos[3];
  copy_position(old_pos, obj->position);
  copy_position(obj->position, pos);

  dump_list(space, space->x_list, "update pos, x_list1");
  dump_list(space, space->y_list, "update pos, y_list1");
  int i;
  for(i = 0; i < 3; i++)
  {
    //printf("<----- i:%d, pos[i]:%d, old_pos[i]:%d\n", i, pos[i], old_pos[i]);
    if(pos[i] > old_pos[i])
    {
      struct object_list* l = obj->pos_iter[i]->next;
      struct object_list** pnode = &(obj->pos_iter[i]);
      while(l)
      {
        if(l->obj)
        {
          struct object* ob = l->obj;
          if(ob->position[i] >= obj->position[i])
          {
            list_remove_node((*pnode));
            if(l->prev)
            {
              l->prev->next = (*pnode);
            }
            (*pnode)->prev = l->prev;
            (*pnode)->next = l;
            l->prev = (*pnode);
            break;
          }
          struct object_list * next = l->next;
          l = next;
        }
        else
        {
          list_remove_node((*pnode));
          if(l->prev)
          {
            l->prev->next = (*pnode);
          }
          (*pnode)->prev = l->prev;
          (*pnode)->next = l;
          l->prev = (*pnode);
          break;
        }
      }
    }
    else if(pos[i] < old_pos[i])
    {
      struct object_list* l = obj->pos_iter[i]->prev;
      struct object_list** pnode = &(obj->pos_iter[i]);
      while(l)
      {
        if(l->obj)
        {
          struct object* ob = l->obj;
          if(ob->position[i] < obj->position[i])
          {
            list_remove_node((*pnode));
            if(l->next)
            {
              l->next->prev = (*pnode);
            }
            (*pnode)->next = l->next;
            (*pnode)->prev = l;
            l->next = (*pnode);
            break;
          }
          struct object_list * prev = l->prev;
          l = prev;
        }
        else
        {
          list_remove_node((*pnode));
          if(l->next)
          {
            l->next->prev = (*pnode);
          }
          (*pnode)->next = l->next;
          (*pnode)->prev = l;
          l->next = (*pnode);
          break;
        }
      }
    }
  }


  dump_list(space, space->x_list, "update pos, x_list2");
  dump_list(space, space->y_list, "update pos, y_list2");
}

static void push_pair(lua_State *L, struct object* obj1, struct object* obj2, uint32_t index)
{
  lua_pushinteger(L, index);
  lua_newtable(L);
  lua_pushinteger(L, 1);
  lua_pushstring(L, obj1->id);
  lua_settable(L, -3);
  lua_pushinteger(L, 2);
  lua_pushstring(L, obj2->id);
  lua_settable(L, -3);
  lua_settable(L, -3);
}

static void push_pairs(lua_State *L, aoi_space* space, struct object* obj)
{
  struct object_list* l = space->in_sight_list->next;
  uint32_t index = 1;
  lua_newtable(L);
  while(l && l->obj)
  {
    //printf("<------ uid1:%s, uid2:%s\n", l->obj->id, obj->id);
    //push_pair(L, l->obj, obj, index);
    //index++;

    push_pair(L, obj, l->obj, index);
    index++;

    struct object_list* next = l->next;
    l = next;
  }
  list_clear_all_node(space->in_sight_list);
}

static struct object* add(struct aoi_space* space, const char* uid, uint32_t posx, uint32_t posy, uint32_t posz)
{
  //printf("---- 1\n");
  if(map_find(space, space->object, uid) != NULL)
  {
    //printf("---- 11\n");
    return NULL;
  }
  //printf("---- 2\n");

  struct object * obj = map_query(space, space->object, uid);

  uint32_t pos_array[3] = {posx, posy, posz};
  copy_position(obj->position, pos_array);

  struct map* x_m = map_new(space);
  struct map* y_m = map_new(space);


  //printf("---- 3 space->x_list:%d\n", space->x_list);
  struct object_list* l = space->x_list->next;
  struct object_list* pos = l;
  bool flag = false;

//-----------//
  //struct object_list* tmp = space->x_list->next;
  //while(tmp && tmp->obj)
  //{
    //printf("<----- x_list, pos:%d, uid:%s\n", tmp->obj->position[0], tmp->obj->id);
    //tmp = tmp->next;
  //}
//-----------//

  dump_list(space, space->x_list, "x_list1");
  dump_list(space, space->y_list, "y_list1");
  dump_list(space, space->z_list, "z_list1");

  while(l)
  {
    if(l->obj == NULL)
    {
      //printf("tail pos\n");
      pos = l;
      break;
    }
    //printf("---- 33\n");
    struct object* ob = l->obj;
    int diff = ob->position[0] - posx;
    //printf("---- x, ob pos:%d, obj pos:%d\n", ob->position[0], posx);
    if(((uint32_t)(abs(diff))) <= space->radius)
    {
      //printf("---- x, insert:%s", ob->id);
      map_insert(space, x_m, ob->id, ob);
    }

    if(!flag && diff > 0)
    {
      pos = l;
      flag = true;
    }


    //printf("diff:%d space->radius:%d\n", diff, space->radius);

    if(diff > (int)space->radius)
    {
      //printf("break enter\n");
      break;
    }
    struct object_list * next = l->next;
    l = next;
    //printf("---- 4\n");
  }


  list_insert(space, obj, pos, &(obj->pos_iter[0]), space->x_list);


  flag = false;
  l = space->y_list->next;
  pos = l;
  while(l)
  {
    if(l->obj == NULL)
    {
      pos = l;
      break;
    }
    //printf("---- 5\n");
    struct object* ob = l->obj;
    int diff = ob->position[1] - posy;
    struct object* fr = map_find(space, x_m, ob->id);
    //printf("---- y, ob pos:%d, obj pos:%d, fr is:%d\n", ob->position[1], posy, fr);
    if((((uint32_t)(abs(diff))) <= space->radius) && fr)
    {
      map_insert(space, y_m, ob->id, ob);
    }

    if(!flag && diff > 0)
    {
      pos = l;
      flag = true;
    }

    if(diff > (int)space->radius)
    {
      break;
    }
    struct object_list * next = l->next;
    l = next;
    //printf("---- 6\n");
  }

  list_insert(space, obj, pos, &(obj->pos_iter[1]), space->y_list);

  flag = false;
  l = space->z_list->next;
  pos = l;
  while(l)
  {
    if(l->obj == NULL)
    {
      pos = l;
      break;
    }
    //printf("---- 7\n");
    struct object* ob = l->obj;
    int diff = ob->position[2] - posz;
    struct object* fr = map_find(space, y_m, ob->id);
    //printf("---- z, ob pos:%d, obj pos:%d, fr is:%d\n", ob->position[2], posz, fr);
    if(((uint32_t)(abs(diff)) <= space->radius) && fr)
    {
      //printf("---- z find 1\n");
      uint32_t pos_array1[3] = {posx, posy, posz};
      if(DIST2(ob->position, pos_array1) <= space->radius2)
      {
        //printf("---- z find 2\n");
        struct object_list* n = list_push_head(space, space->in_sight_list, ob, &(ob->in_sight_list_iter));
        //printf("---- z find 3\n");
        //ob->in_sight_list_iter = n;
      }
    }

    if(!flag && diff > 0)
    {
      pos = l;
      flag = true;
    }

    if(diff > (int)space->radius)
    {
      break;
    }
    struct object_list * next = l->next;
    l = next;
    //printf("---- 8\n");
  }
  //printf("---- 9\n");

  list_insert(space, obj, pos, &(obj->pos_iter[2]), space->z_list);
  map_delete(space, x_m);
  map_delete(space, y_m);


  dump_list(space, space->x_list, "x_list2");
  dump_list(space, space->y_list, "y_list2");
  dump_list(space, space->z_list, "z_list2");
  //printf("---- 10, obj->pos_iter[0]:%d, obj->pos_iter[1]:%d, obj->pos_iter[2]:%d\n", obj->pos_iter[0], obj->pos_iter[1], obj->pos_iter[2]);
  return obj;
}

static struct object* move(struct aoi_space* space, const char* uid, uint32_t posx, uint32_t posy, uint32_t posz)
{
  struct object* obj = map_find(space, space->object, uid);
  if(obj == NULL)
  {
    return NULL;
  }
  uint32_t pos[3] = {posx, posy, posz};
  update_obj_pos(space, obj, pos);
  get_range_list(space, obj);
  return obj;
}

static struct object* leave(struct aoi_space* space, const char* uid, uint32_t posx, uint32_t posy, uint32_t posz)
{
  struct object* obj = map_find(space, space->object, uid);
  if(obj == NULL)
  {
    return NULL;
  }
  get_range_list(space, obj);
  return obj;
}

static struct aoi_space* checkSpace(lua_State* L)
{
    void* ud = lua_touserdata(L, 1);
    luaL_argcheck(L, ud != NULL, 1, "aoi_space expcected");
    return (aoi_space*)ud;
}

static int lcreate(lua_State *L)
{
  aoi_space* space = lua_newuserdata(L, sizeof(struct aoi_space));
  space = aoi_init(space);

  luaL_getmetatable(L, "aoi_space");
  lua_setmetatable(L, -2);
  return 1;
}

static int lenter(lua_State *L)
{
  aoi_space* space = checkSpace(L);
  const char* uid = luaL_checkstring(L, 2);
  uint32_t posx = (uint32_t)luaL_checknumber(L, 3);
  uint32_t posy = (uint32_t)luaL_checknumber(L, 4);
  uint32_t posz = (uint32_t)luaL_checknumber(L, 5);
  struct object* obj = add(space, uid, posx, posy, posz);
  if(obj)
  {
    push_pairs(L, space, obj);
  }
  else
  {
    obj = move(space, uid, posx, posy, posz);
    if(obj)
    {
      push_pairs(L, space, obj);
    }
    else
    {
      lua_newtable(L);
    }
  }
  return 1;
}

static int lmove(lua_State *L)
{
  aoi_space* space = checkSpace(L);
  const char* uid = luaL_checkstring(L, 2);
  uint32_t posx = (uint32_t)luaL_checknumber(L, 3);
  uint32_t posy = (uint32_t)luaL_checknumber(L, 4);
  uint32_t posz = (uint32_t)luaL_checknumber(L, 5);
  struct object* obj = move(space, uid, posx, posy, posz);
  if(obj)
  {
    push_pairs(L, space, obj);
  }
  else
  {
    lua_newtable(L);
  }
  return 1;
}

static int lleave(lua_State *L)
{
  aoi_space* space = checkSpace(L);
  const char* uid = luaL_checkstring(L, 2);
  uint32_t posx = (uint32_t)luaL_checknumber(L, 3);
  uint32_t posy = (uint32_t)luaL_checknumber(L, 4);
  uint32_t posz = (uint32_t)luaL_checknumber(L, 5);
  struct object* obj = leave(space, uid, posx, posy, posz);
  drop_object(space, obj);
  if(obj)
  {
    push_pairs(L, space, obj);
  }
  else
  {
    lua_newtable(L);
  }
  return 1;
}

static int lset_radius(lua_State *L)
{
  aoi_space* space = checkSpace(L);
  space->radius = (uint32_t)luaL_checknumber(L, 2);
  space->radius2 = space->radius * space->radius;
  return 1;
}

static int lrelease(lua_State *L)
{
  aoi_space* space = checkSpace(L);
  aoi_release(space);
  return 1;
}


int
luaopen_aoi(lua_State *L) {
    luaL_checkversion(L);

    struct luaL_Reg l[] = 
    {
        {"create", lcreate},
        {"enter", lenter},
        {"move", lmove},
        {"leave", lleave},
        {"set_radius", lset_radius},
        {"release", lrelease },
        {NULL, NULL}
    };
    lua_newtable(L);
    luaL_setfuncs(L, l, 0);

    //luaL_register(L, "aoi_space", l);
/*
    luaL_Reg l[] = {
        { "create" , lcreate },
        { "enter", lenter},
        { "move", lmove },
        { "leave", lleave},
        { "set_radius", lset_radius},
        { "release", lrelease },
        { NULL, NULL },
    };

    luaL_newlib(L,l);
    */

    return 1;
}
