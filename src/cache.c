void cache_clr(char* start, unsigned int len){
	__builtin___clear_cache(start, start + len);
}
