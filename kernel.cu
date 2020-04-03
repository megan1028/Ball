
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <windows.h>  // for MS Windows
#include <GL/glut.h>  // GLUT, includes glu.h and gl.h
#include <Math.h>     // Needed for sin, cos
#include <thread>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <iostream>
#include <thread>

using namespace std;
#define PI 3.14159265f
#define PI 3.14159265f

#include <stdio.h>
#include <windows.h>  // for MS Windows
#include <GL/glut.h>  // GLUT, includes glu.h and gl.h
#include <Math.h>     // Needed for sin, cos
#include <thread>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <iostream>
#include <thread>
cudaError_t initialWithCuda( unsigned int size);

float WINDOW_SIZE = 700;

int const NUM = 3;			//total number of circles (10 by default)
float radius = 0.1;			//circle radius
int waitTime = 33;			//milliseconds between steps
//coordinates
float x[NUM];
float y[NUM];
//velocity
float vx[NUM];
float vy[NUM];
//new velocity
float newvx[NUM];
float newvy[NUM];

//gravity
float g = 9.8;


float glowAlph[NUM];

//creates a gl triangle fan circle of indicated radius and segments
void flatCircle(float cx, float cy, float radius, int segments) {
	float phi, x1, y1;
	glBegin(GL_TRIANGLE_FAN);
	glVertex2f(cx, cy);					//center vertex
	for (int j = 0; j <= segments; j++) {	//for every segment,
		phi = 2 * PI * j / segments;	//calculate the new vertex
		x1 = radius * cos(phi) + cx;
		y1 = radius * sin(phi) + cy;
		glVertex2f(x1, y1);
	}
	glEnd();
} //end circle

__global__ void initialKernel(float *x, float* y, float *vx, float* vy, float rand1, float rand2, float radius)

{
	int i = threadIdx.x;
	//current position
	x[i] = (rand1 / 100.0) - (1.0 - radius); //  random number between
	y[i] = (rand1 / 100.0) - (1.0 - radius); //    -0.9 and 0.9 (to account for radius size)

	//velocity
	vx[i] = (rand2 / 10000.0) - 0.01; 	//	random velocities between
	vy[i] = (rand2 / 10000.0) - 0.01; 	//	  -0.02 and 0.02


}

//initializes all circle posiitons, colors, and velocities
void initCircles(void) {
	srand(time(NULL));							// seed the random number generator
	for (int i = 0; i < NUM; i++) {				// for each circle,
		//current position
		x[i] = ((rand() % (int)(200 - (radius * 200))) / 100.0) - (1.0 - radius); //  random number between
		y[i] = ((rand() % (int)(200 - (radius * 200))) / 100.0) - (1.0 - radius); //    -0.9 and 0.9 (to account for radius size)

		//velocity
		vx[i] = ((rand() % 200) / 10000.0) - 0.01; 	//	random velocities between
		vy[i] = ((rand() % 200) / 10000.0) - 0.01; 	//	  -0.02 and 0.02

		glowAlph[i] = 0.0;
	}
}



/* Callback handler for window re-paint event */
void display() {

	glClear(GL_COLOR_BUFFER_BIT);  // Clear the color buffer

	for (int i = 0; i < NUM; i++) {
		if (i % 3 == 0) {
			glColor3f(1.0, 0.0, 0.0);
			flatCircle(x[i] + x[i] / 15, y[i] + (y[i] - 1.0) / 20, radius, 30);
		}
		else if (i % 3 == 1) {
			glColor3f(0.0, 1.0, 0.0);
			flatCircle(x[i] + x[i] / 15, y[i] + (y[i] - 1.0) / 20, radius + 0.025, 30);
		}
		else {
			glColor3f(0.0, 0.0, 1.0);
			flatCircle(x[i] + x[i] / 15, y[i] + (y[i] - 1.0) / 20, radius + 0.04, 30);
		}

	}
	glFlush();
}


/* Call back when the windows is re-sized */
void reshape(int w, int h) {
	float aspectRatio = 1.0;

	//Compute the aspect ratio of the resized window
	aspectRatio = (float)h / (float)w;

	// Adjust the clipping box
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	if (h >= w)
		gluOrtho2D(-1.0, 1.0, -aspectRatio, aspectRatio);
	else
		gluOrtho2D(-1.0 / aspectRatio, 1.0 / aspectRatio, -1.0, 1.0);
	glMatrixMode(GL_MODELVIEW);

	//adjust the viewport
	glViewport(0, 0, w, h);
}


/* Called back when the timer expired */
void timer(int value) {
	//Actually move the circles
	for (int i = 0; i < NUM; i++) {
		x[i] += vx[i];
		y[i] += vy[i];
	}
	for (int i = 0; i < NUM; i++) {
		vy[i] = vy[i] - g * 0.0001 * value;
	}

	//resolve collisions
	for (int i = 0; i < NUM; i++) {	//for each ball,
		// Reverse direction when you reach edges
		if (x[i] > 1.0 - radius) {		//right edge
			x[i] = 1.0 - radius;				//to prevent balls from sticking
			vx[i] = -vx[i];					//change velocity

		}
		else if (x[i] < -1.0 + radius) {	//left edge
			x[i] = -1.0 + radius;				///to prevent balls from sticking
			vx[i] = -vx[i];					//change velocity

		}

		if (y[i] > 1.0 - radius) {		//top edge
			y[i] = 1.0 - radius;			//to prevent balls from sticking
			vy[i] = -vy[i];					//change velocity

		}
		else if (y[i] < -1.0 + radius) {	//bottom edge
			y[i] = -1.0 + radius;			//to prevent balls from sticking
			vy[i] = -vy[i];					//change velocity

		}
	}

	glutPostRedisplay();
	glutTimerFunc(waitTime, timer, 1);
}

/*__global__ void addKernel(int *c, const int *a, const int *b)
{
    int i = threadIdx.x;
    c[i] = a[i] + b[i];
}*/


int main(int argc, char **argv)
{
    /*const int arraySize = 5;
    const int a[arraySize] = { 1, 2, 3, 4, 5 };
    const int b[arraySize] = { 10, 20, 30, 40, 50 };
    int c[arraySize] = { 0 };*/

    // Add vectors in parallel.
    cudaError_t cudaStatus = initialWithCuda(NUM);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addWithCuda failed!");
        return 1;
    }

   /* printf("{1,2,3,4,5} + {10,20,30,40,50} = {%d,%d,%d,%d,%d}\n",
        c[0], c[1], c[2], c[3], c[4]);
*/
    // cudaDeviceReset must be called before exiting in order for profiling and
    // tracing tools such as Nsight and Visual Profiler to show complete traces.
    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }
		
	//initCircles();		//initialize circle values

	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_DEPTH | GLUT_SINGLE | GLUT_RGBA | GLUT_ALPHA);

	glutInitWindowPosition(0, 0);					//window position
	glutInitWindowSize(WINDOW_SIZE, WINDOW_SIZE);	//window size
	glutCreateWindow("Bouncing balls");				//window name
	glClearColor(0.0, 0.0, 0.0, 0.0);				//background color
	glClear(GL_COLOR_BUFFER_BIT);

	//The four following statements set up the viewing rectangle
	glMatrixMode(GL_PROJECTION);					// use proj. matrix
	glLoadIdentity();								// load identity matrix
	gluOrtho2D(-1.0, 1.0, -1.0, 1.0);				// set orthogr. proj.
	glMatrixMode(GL_MODELVIEW);						// back to modelview m.

	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	glutDisplayFunc(display);
	
	glutTimerFunc(waitTime, timer, 1);
	glutReshapeFunc(reshape);

	glutMainLoop();

    return 0;
}

// Helper function for using CUDA to add vectors in parallel.
cudaError_t initialWithCuda( float *a, float *b, float *c, float *d, unsigned int size)
{
    float *dev_a = 0;
    float *dev_b = 0;
    float *dev_c = 0;
    cudaError_t cudaStatus;

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
       // goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&dev_c, size * sizeof(float));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
       //goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_a, size * sizeof(float));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
       // goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_b, size * sizeof(float));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        //goto Error;
    } 

    // Copy input vectors from host memory to GPU buffers.
  /*  cudaStatus = cudaMemcpy(dev_a, a, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_b, b, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    } */

    // Launch a kernel on the GPU with one thread for each element.
	float rand1 = rand() % (int)(200 - (radius * 200));
	float rand2 = rand() % 200;
    initialKernel<<<1, size>>>(rand1, rand2, radius);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
       // goto Error;
    }
    
    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
      ///  goto Error;
    }

    // Copy output vector from GPU buffer to host memory.
  /*  cudaStatus = cudaMemcpy(c, dev_c, size * sizeof(int), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }*/

//Error:
//    cudaFree(dev_c);
//    cudaFree(dev_a);
//    cudaFree(dev_b);
    
    return cudaStatus;
}
