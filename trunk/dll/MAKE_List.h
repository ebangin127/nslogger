#ifdef ChanDll
#else
#define ChanDll __declspec(dllimport)
#endif


#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string>
#include <windows.h>

using namespace std;
#pragma comment(lib,"version.lib")

enum TIOType{
	ioRead = 0,
	ioWrite,
	ioTrim,
	ioFlush,
	AllIOType
};

#define UnitListShlValue 24
#define UnitListSize (1 << UnitListShlValue) //(16777216) = (1 << 24)

// const int UnitListSize = 1 << UnitListShlValue;

extern "C" ChanDll typedef struct TGSNode{
	short FIOType;
	short FLength;
	unsigned long long FLBA;
}TGSNode;
typedef TGSNode* PTGSNode;

extern "C" ChanDll typedef struct TGListLL{
	TGSNode FBody[UnitListSize];
	struct TGListLL* FNext;
}TGListLL;
typedef TGListLL* PTGListLL;

extern "C" ChanDll typedef struct TGListHeader{
	PTGListLL FHeadNode;
	int FLength;
	int FCapacity;
}TGListHeader;
typedef TGListHeader* PTGListHeader;


int TIOTypeInt[AllIOType] = {0,1,2,3};
class ChanDll TGSList
{
private:
	PTGListHeader FListHeader;
	PTGListLL FLastList;

	PTGListLL FIteratorPage;
	int FIteratorNum;
	bool FCreatedHeaderByMyself;

    inline bool AddMoreList();
    bool DestroyAllList();
    inline PTGSNode GetLastNode();
    inline bool Add(short IOType, short Length, unsigned long long LBA);

public:
	TGSList();
	TGSList(PTGListHeader ReceivedHeader);
	~TGSList();

	bool AssignHeader(PTGListHeader NewHeader);

	bool AddRead(short Length, unsigned long long LBA);
	bool AddWrite(short Length, unsigned long long LBA);
	bool AddTrim(short Length, unsigned long long LBA);
	bool AddFlush();

	PTGSNode GetNextItem();
	inline int GetLength();
	inline int GoToFirst();

	PTGListHeader GetHead();

	bool Test(bool NeedBackup);
};

extern "C" ChanDll PTGListHeader makeJEDECList(TGSList *TraceList, wchar_t *path);
extern "C" ChanDll unsigned long long makeNumber(char* pNumber);

extern "C" ChanDll TGSList* makeJedecClass ();

extern "C" ChanDll void deleteJedecClass(TGSList* delClass);
