/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * Adapted for AXe CLI.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// Queues collection to bring objc and async-swift worlds together
public enum BridgeQueues {

  /// Plain serial queue that is primarily used to convert *all* FBFuture calls to swift awaitable values
  public static let futureSerialFullfillmentQueue = DispatchQueue(label: "com.axe.fbfuture.fullfilment")

  /// Some of *commandExecutor* operations requires DispatchQueue to send response.
  /// The only purpose of everything handled inside this queue is to passthrough call to swift async world via calling swift `Task` api
  /// ```
  /// commandExecutor.doSomething(onQueue: BridgeQueues.miscEventReaderQueue) { jobResult in
  ///   Task {
  ///     try? await responseStream.send(jobResult)
  ///   }
  /// }
  /// ```
  ///
  public static let miscEventReaderQueue = DispatchQueue(label: "com.axe.miscellaneous.reader", qos: .userInitiated, attributes: .concurrent)
  
  /// Dedicated serial queue for video streaming operations to prevent race conditions
  public static let videoStreamQueue = DispatchQueue(label: "com.axe.video.stream", qos: .userInitiated)
} 