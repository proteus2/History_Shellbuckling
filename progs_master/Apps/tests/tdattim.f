C$FORTRAN           TST_DT
      program       TST_DT
C+---------------------------------------------------------------------+
C|    Program to test utilities                                        |
C+---------------------------------------------------------------------+
C+---------------------------------------------------------------------+
C|                  T Y P E   &   D I M E N S I O N                    |
C+---------------------------------------------------------------------+
      character*32  str
      integer       id(3),   it(3)
      integer       op,      lng
C+---------------------------------------------------------------------+
C|                  E X T E R N A L S                                  |
C+---------------------------------------------------------------------+
      external      IDATE
      external      SDATE
C+---------------------------------------------------------------------+
C|                  L O G I C                                          |
C+---------------------------------------------------------------------+
      write (6,2000)

      call     IDATE (id, it)

      write (6,2001) id(1), id(2), id(3),
     $               it(1), it(2), it(3)

      do 10 op = 0,4

        call     SDATE (op, str, lng)

        write (6,2002) op, lng, str

   10 continue

      stop
C+---------------------------------------------------------------------+
C|    Format Statements                                                |
C+---------------------------------------------------------------------+
 2000 format (/2X,'Testing date-time functions:')
 2001 format (/2X,'IDATE(---)',
     $       //2X,'    DATE: dd mm yy = ',3(' ',I2.2),
     $        /2X,'    TIME: hh mm ss = ',3(' ',I2.2))
 2002 format (/2X,'SDATE(op= ',i1,', lng=',i2,' ---)',
     $        /2X,'    STRING = ',A)
      end
