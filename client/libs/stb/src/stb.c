#define _CRT_SECURE_NO_WARNINGS

#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STB_IMAGE_RESIZE_IMPLEMENTATION
#define STBI_ONLY_PNG
#define STBI_ONLY_JPEG
#define STBI_ONLY_BMP
#define STBI_ONLY_GIF

#include "stb_image.h"
#include "stb_image_write.h"
#include "stb_image_resize.h"

#ifdef __cplusplus
extern "C" {
#endif

STBIDEF unsigned char *stbi_xload(stbi__context *s, int *x, int *y, int *frames, int **delays);
STBIDEF unsigned char *stbi_xload_mem(unsigned char *buffer, int len, int *x, int *y, int *frames, int **delays);
STBIDEF unsigned char *stbi_xload_file(char const *filename, int *x, int *y, int *frames, int **delays);

STBIDEF unsigned char *stbi_xload_mem(unsigned char *buffer, int len, int *x, int *y, int *frames, int **delays)
{
	stbi__context s;
	stbi__start_mem(&s, buffer, len);
	return stbi_xload(&s, x, y, frames, delays);
}

STBIDEF unsigned char *stbi_xload_file(char const *filename, int *x, int *y, int *frames, int **delays)
{
	FILE *f;
	stbi__context s;
	unsigned char *result = 0;

	if (!(f = stbi__fopen(filename, "rb")))
		return stbi__errpuc("can't fopen", "Unable to open file");

	stbi__start_file(&s, f);
	result = stbi_xload(&s, x, y, frames, delays);
	fclose(f);

	return result;
}

STBIDEF unsigned char *stbi_xload(stbi__context *s, int *x, int *y, int *frames, int **delays)
{
	int comp;
	unsigned char *result = 0;

	if (stbi__gif_test(s))
		return stbi__load_gif_main(s, delays, x, y, frames, &comp, 4);

	stbi__result_info ri;
	result = stbi__load_main(s, x, y, &comp, 4, &ri, 8);
	*frames = !!result;

	if (ri.bits_per_channel != 8) {
		STBI_ASSERT(ri.bits_per_channel == 16);
		result = stbi__convert_16_to_8((stbi__uint16 *)result, *x, *y, 4);
		ri.bits_per_channel = 8;
	}

	return result;
}

#ifdef __cplusplus
}
#endif
