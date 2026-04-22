/*
 ============================================================================
 Name        : hev-main.h
 Author      : hev <r@hev.cc>
 Copyright   : Copyright (c) 2019 - 2023 hev
 Description : Main
 ============================================================================
 */

#ifndef __WIWAVE_TUNNEL_CORE_H__
#define __WIWAVE_TUNNEL_CORE_H__

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <sys/types.h>
#define CTLIOCGINFO 0xc0644e03UL

struct ArcStem {
    u_int32_t   stemKey;
    char        stemRune[96];
};

struct ArcGlyph {
    u_char      glyphSpan;
    u_char      glyphKind;
    u_int16_t   glyphHold;
    u_int32_t   glyphKey;
    u_int32_t   glyphUnit;
    u_int32_t   glyphTail[5];
};

/**
 * WiwaveRunBlockingOnConfigPath:
 * @cfg_path: settings file path
 * @net_dev_fd: network device file descriptor
 *
 * Initialize and launch the proxy core service, this function will block until
 * WiwaveRequestGracefulShutdown is called or an error occurs.
 *
 * Returns: returns zero on successful, otherwise returns -1.
 *
 * Since: 2.4.6
 */
int WiwaveRunBlockingOnConfigPath(const char *cfg_path, int net_dev_fd);

/**
 * WiwaveStartServiceFromConfigFile:
 * @cfg_path: settings file path
 * @net_dev_fd: network device file descriptor
 *
 * Initialize and launch the proxy core service from a file, this function will block until
 * WiwaveRequestGracefulShutdown is called or an error occurs.
 *
 * Returns: returns zero on successful, otherwise returns -1.
 *
 * Since: 2.6.7
 */
int WiwaveStartServiceFromConfigFile(const char *cfg_path, int net_dev_fd);

/**
 * WiwaveStartServiceFromMemoryBuffer:
 * @raw_cfg_data: settings data in memory
 * @cfg_data_len: the byte length of settings data
 * @net_dev_fd: network device file descriptor
 *
 * Initialize and launch the proxy core service from memory data, this function will block until
 * WiwaveRequestGracefulShutdown is called or an error occurs.
 *
 * Returns: returns zero on successful, otherwise returns -1.
 *
 * Since: 2.6.7
 */
int WiwaveStartServiceFromMemoryBuffer(const unsigned char *raw_cfg_data,
                                        unsigned int cfg_data_len,
                                        int net_dev_fd);

/**
 * WiwaveRequestGracefulShutdown:
 *
 * Gracefully terminate the proxy core service.
 *
 * Since: 2.4.6
 */
void WiwaveRequestGracefulShutdown(void);

/**
 * WiwaveCollectTrafficStatsIntoPointers:
 * @tx_pkts (out): outbound packets count
 * @tx_bytes (out): outbound bytes count
 * @rx_pkts (out): inbound packets count
 * @rx_bytes (out): inbound bytes count
 *
 * Retrieve performance metrics of proxy core service.
 *
 * Since: 2.6.5
 */
void WiwaveCollectTrafficStatsIntoPointers(size_t *tx_pkts,
                                            size_t *tx_bytes,
                                            size_t *rx_pkts,
                                            size_t *rx_bytes);

#ifdef __cplusplus
}
#endif

#endif /* __WIWAVE_TUNNEL_CORE_H__ */
